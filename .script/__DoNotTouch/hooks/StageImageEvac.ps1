param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][string]$GitExe,
    [Parameter(Mandatory=$true)][hashtable]$Cfg
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Message, [string]$RepoRoot, [string]$LogPath, [switch]$ConsoleOnly)
    $line = "[{0}] {1}" -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"), $Message
    Write-Host $line
    if (-not $ConsoleOnly) {
        Add-Content -LiteralPath (Join-Path $RepoRoot $LogPath) -Value $line
    }
}

function Get-StagedPaths {
    param([string]$GitExe)
    & $GitExe diff --cached --name-only --diff-filter=AM |
        Where-Object { $_ } |
        ForEach-Object { $_.Trim() }
}


function Normalize-Rel {
    param([string]$RelPath)
    $p = ($RelPath -replace "\\","/")
    $p = $p.TrimStart("/")
    if ($p.StartsWith("./")) { $p = $p.Substring(2) }
    if ($p.StartsWith(".\")) { $p = $p.Substring(2) }
    return $p
}

function Is-TargetImage {
    param([string]$RelPath, [hashtable]$Cfg)
    $attRoot = $Cfg.ATTACHMENT_ROOT
    $imgExts = ($Cfg.IMAGE_EXTS -split "," | ForEach-Object { $_.Trim().ToLower() })
    $norm = Normalize-Rel $RelPath
    if (-not $norm.ToLower().StartsWith(($attRoot.ToLower() + "/"))) { return $false }
    $ext = ([System.IO.Path]::GetExtension($norm)).ToLower()
    if (-not ($imgExts -contains $ext)) { return $false }
    return $true
}

function Should-Use-Robocopy {
    param([long]$SizeBytes, [hashtable]$Cfg)
    if ($Cfg.ROBOCOPY_ENABLE.ToLower() -ne "true") { return $false }
    $thresholdMB = [int]$Cfg.ROBOCOPY_THRESHOLD_MB
    return ([Math]::Floor($SizeBytes / 1MB) -ge $thresholdMB)
}

function Copy-OneFile {
    param([string]$SrcAbs, [string]$DstAbs, [hashtable]$Cfg, [string]$RepoRoot)
    $logPath = $Cfg.LOG_PATH
    $dry     = ($Cfg.DRY_RUN.ToLower() -eq "true")

    if (-not (Test-Path -LiteralPath $SrcAbs)) {
        Write-Log -Message "WARN: source missing -> $SrcAbs" -RepoRoot $RepoRoot -LogPath $logPath
        return
    }

    $srcFi = Get-Item -LiteralPath $SrcAbs
    $sizeBytes = $srcFi.Length
    $sizeMB = [Math]::Round($sizeBytes / 1MB)
    $useRobo = Should-Use-Robocopy -SizeBytes $sizeBytes -Cfg $Cfg

    $dstDir = Split-Path -LiteralPath $DstAbs -Parent
    if (-not (Test-Path -LiteralPath $dstDir)) {
        if (-not $dry) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
    }

    if ($useRobo) {
        Write-Log -Message "COPY(robo): $SrcAbs -> $DstAbs (${sizeMB}MB)" -RepoRoot $RepoRoot -LogPath $logPath
        if (-not $dry) {
            $srcDir   = Split-Path -LiteralPath $SrcAbs -Parent
            $fileName = Split-Path -LiteralPath $SrcAbs -Leaf
            $opts = @("/R:$($Cfg.ROBOCOPY_R)", "/W:$($Cfg.ROBOCOPY_W)", "/NFL", "/NDL", "/NP", "/NJS", "/NJH", "/XO")
            $roboMT = [int]$Cfg.ROBOCOPY_MT
            if ($roboMT -gt 1) { $opts += "/MT:$roboMT" }
            if ($Cfg.ROBOCOPY_J.ToLower() -eq "true") { $opts += "/J" }
            & robocopy $srcDir $dstDir $fileName $opts
            if ($LASTEXITCODE -ge 8) { throw "Robocopy failed ($LASTEXITCODE): $SrcAbs" }
        }
        return
    }

    $mode      = $Cfg.COPY_MODE.ToLower()   # "hash" | "mtime"
    $largeMB   = [int]$Cfg.LARGE_FILE_MB
    $hashLarge = ($Cfg.HASH_LARGE.ToLower() -eq "true")
    $doHash    = ($mode -eq "hash") -and (($sizeMB -lt $largeMB) -or $hashLarge)

    $needCopy = $true
    if (Test-Path -LiteralPath $DstAbs) {
        $dstFi = Get-Item -LiteralPath $DstAbs
        if ($doHash) {
            $srcHash = (Get-FileHash -LiteralPath $SrcAbs -Algorithm SHA256).Hash
            $dstHash = (Get-FileHash -LiteralPath $DstAbs -Algorithm SHA256).Hash
            $needCopy = ($srcHash -ne $dstHash)

            $why = "HASH-same"
            if ($needCopy) { $why = "HASH-diff" }
            Write-Log -Message ("DECIDE(hash): {0} ({1} MB) -> {2} [{3}]" -f $SrcAbs, $sizeMB, $DstAbs, $why) -RepoRoot $RepoRoot -LogPath $logPath
        } else {
            $needCopy = ($srcFi.Length -ne $dstFi.Length) -or ($srcFi.LastWriteTimeUtc -gt $dstFi.LastWriteTimeUtc)

            $why = "MTIME/size same"
            if ($needCopy) { $why = "MTIME/size newer" }
            Write-Log -Message ("DECIDE(mtime): {0} ({1} MB) -> {2} [{3}]" -f $SrcAbs, $sizeMB, $DstAbs, $why) -RepoRoot $RepoRoot -LogPath $logPath
        }
    }

    if ($needCopy) {
        Write-Log -Message "COPY(copy): $SrcAbs -> $DstAbs (${sizeMB}MB)" -RepoRoot $RepoRoot -LogPath $logPath
        if (-not $dry) { Copy-Item -LiteralPath $SrcAbs -Destination $DstAbs -Force }
    } else {
        Write-Log -Message "SKIP(copy): $SrcAbs -> $DstAbs (no change)" -RepoRoot $RepoRoot -LogPath $logPath
    }
}


function Delete-Original {
    param([string]$RelPath, [string]$GitExe, [hashtable]$Cfg, [string]$RepoRoot)
    $logPath = $Cfg.LOG_PATH
    $dry     = ($Cfg.DRY_RUN.ToLower() -eq "true")
    Write-Log -Message "DELETE(img): $RelPath (index+worktree)" -RepoRoot $RepoRoot -LogPath $logPath
    if (-not $dry) { & $GitExe rm -f -- "$RelPath" }
}

function Main {
    $logPath    = $Cfg.LOG_PATH
    $uploadRoot = $Cfg.UPLOAD_ROOT
    $userId     = $Cfg.USER_ID
    $dry        = ($Cfg.DRY_RUN.ToLower() -eq "true")

    Write-Log -Message "BEGIN StageImageEvac (dry=$dry)" -RepoRoot $RepoRoot -LogPath $logPath

    $targets = Get-StagedPaths -GitExe $GitExe | Where-Object { Is-TargetImage -RelPath $_ -Cfg $Cfg }
    Write-Log -Message "TARGET images: $($targets.Count)" -RepoRoot $RepoRoot -LogPath $logPath
    if ($targets.Count -eq 0) {
        Write-Log -Message "END StageImageEvac (no target)" -RepoRoot $RepoRoot -LogPath $logPath
        return
    }

    $userRoot = Join-Path $uploadRoot $userId
    if (-not (Test-Path -LiteralPath $userRoot)) {
        if (-not $dry) { New-Item -ItemType Directory -Force -Path $userRoot | Out-Null }
    }

    foreach ($rel in $targets) {
        $relNative = ($rel -replace "/", "\")
        $srcAbs = Join-Path $RepoRoot $relNative
        $dstAbs = Join-Path $userRoot $relNative

        Copy-OneFile -SrcAbs $srcAbs -DstAbs $dstAbs -Cfg $Cfg -RepoRoot $RepoRoot

        if ($Cfg.DELETE_ORIGINAL.ToLower() -eq "true") {
            Delete-Original -RelPath $rel -GitExe $GitExe -Cfg $Cfg -RepoRoot $RepoRoot
        } else {
            Write-Log -Message "SKIP(delete): DELETE_ORIGINAL=false ($rel)" -RepoRoot $RepoRoot -LogPath $logPath
        }
    }

    Write-Log -Message "END StageImageEvac (OK)" -RepoRoot $RepoRoot -LogPath $logPath
}

try { Main }
catch {
    Write-Log -Message ("ERROR(StageImageEvac): " + $_.Exception.Message) -RepoRoot $RepoRoot -LogPath ($Cfg.LOG_PATH) -ConsoleOnly
    throw
}
