<#
========================================================================
 RewriteMdLinks.ps1 (PowerShell 5.1)
 目的:
   - ステージ済み .md の画像参照（__Attachment/ 配下・SVG除外）を
     UPLOAD_URL_ROOT/{USER_ID}/<repo相対パス> へ置換
   - 置換が発生した .md は git add で再ステージ
   - CLI と uploads.log に記録
   - DRY_RUN は書き換え／再ステージを抑止してログのみ
========================================================================
#>

param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][string]$GitExe,
    [Parameter(Mandatory=$true)][hashtable]$Cfg
)

$ErrorActionPreference = 'Stop'

function Write-Log {
    param(
        [string]$Message,
        [string]$RepoRoot,
        [string]$LogPath,
        [switch]$ConsoleOnly
    )
    $timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    $line = "[$timestamp] $Message"
    Write-Host $line
    if (-not $ConsoleOnly) {
        $logFile = Join-Path $RepoRoot $LogPath
        if (-not (Test-Path -LiteralPath $logFile)) {
            New-Item -ItemType File -Path $logFile -Force | Out-Null
        }
        Add-Content -LiteralPath $logFile -Value $line
    }
}

function Get-StagedPaths {
    param([string]$GitExe)
    $out = & $GitExe diff --cached --name-only --diff-filter=AM
    return ($out -split "`n" | Where-Object { $_ -and $_.Trim() -ne '' }) |
           ForEach-Object { $_.Trim() }
}

function Normalize-Rel {
    param([string]$RelOrRef)
    $p = ($RelOrRef -replace '\\','/')
    if ($p.StartsWith('./')) { $p = $p.Substring(2) }
    $p = $p.TrimStart('/')
    return $p
}

function Is-AbsoluteUrl {
    param([string]$Ref)
    $l = $Ref.ToLower()
    return ($l.StartsWith('http://') -or $l.StartsWith('https://') -or $l.StartsWith('file://'))
}

function Map-PathToFileUrl {
    param(
        [string]$RefPath,
        [hashtable]$Cfg
    )
    if (Is-AbsoluteUrl $RefPath) { return $null }

    # 仕様: IMAGE_EXTS は ".png,.jpg,.jpeg" のようにドット付き拡張子を列挙
    $attRoot = $Cfg['ATTACHMENT_ROOT']
    $imgExts = ($Cfg['IMAGE_EXTS'] -split ',' | ForEach-Object { $_.Trim().ToLower() })
    $urlRoot = ($Cfg['UPLOAD_URL_ROOT']).TrimEnd('/')
    $userId  = $Cfg['USER_ID']

    $norm = Normalize-Rel $RefPath
    if (-not ($norm.ToLower().StartsWith($attRoot.ToLower() + '/'))) { return $null }

    $ext = ([System.IO.Path]::GetExtension($norm)).ToLower()
    if (-not ($imgExts -contains $ext)) { return $null }

    return "$urlRoot/$userId/$norm"
}

function Rewrite-MarkdownContent {
    param(
        [string]$Content,
        [hashtable]$Cfg
    )
    # 1 = "!\[[^\]]*\]\(" (prefix)
    # 2 = path（置換対象: 空白不可）
    # 3 = tail（"title" 等そのまま維持）
    # 4 = ")" (closing)
    $patternMd = '(!\[[^\]]*\]\()([^\)\s]+)([^\)]*)(\))'

    $matches = [System.Text.RegularExpressions.Regex]::Matches(
        $Content, $patternMd, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
    )

    if ($matches.Count -eq 0) { return ,@($Content, 0) }

    $sb = New-Object System.Text.StringBuilder
    $pos = 0
    $changed = 0

    foreach ($m in $matches) {
        [void]$sb.Append($Content.Substring($pos, $m.Index - $pos))

        $prefix = $m.Groups(1).Value
        $path   = $m.Groups(2).Value
        $tail   = $m.Groups(3).Value
        $close  = $m.Groups(4).Value

        $mapped = Map-PathToFileUrl -RefPath $path -Cfg $Cfg

        if ($mapped) {
            [void]$sb.Append($prefix)
            [void]$sb.Append($mapped)
            [void]$sb.Append($tail)
            [void]$sb.Append($close)
            $changed += 1
        } else {
            [void]$sb.Append($m.Value)
        }

        $pos = $m.Index + $m.Length
    }

    if ($pos -lt $Content.Length) {
        [void]$sb.Append($Content.Substring($pos))
    }

    return ,@($sb.ToString(), $changed)
}

function Main {
    $logPath     = $Cfg['LOG_PATH']
    $dry         = ($Cfg['DRY_RUN'].ToLower() -eq 'true')
    $rewriteMd   = ($Cfg['REWRITE_MD'].ToLower() -eq 'true')
    $stagedOnly  = ($Cfg['MD_STAGED_ONLY'].ToLower() -eq 'true')

    Write-Log -Message "BEGIN RewriteMdLinks (dry=$dry, stagedOnly=$stagedOnly)" -RepoRoot $RepoRoot -LogPath $logPath

    if (-not $rewriteMd) {
        Write-Log -Message 'SIP(all): REWRITE_MD=false' -RepoRoot $RepoRoot -LogPath $logPath
        return
    }

    $targets = @()
    if ($stagedOnly) {
        $staged = Get-StagedPaths -GitExe $GitExe
        foreach ($p in $staged) {
            if ([System.IO.Path]::GetExtension($p).ToLower() -eq '.md') { $targets += $p }
        }
    } else {
        # 相対化は Replace の方が安全
        Get-ChildItem -LiteralPath $RepoRoot -Recurse -Filter *.md | ForEach-Object {
            $rel = $_.FullName.Replace($RepoRoot, '').TrimStart('\','/')
            $targets += $rel
        }
    }

    Write-Log -Message "TARGET markdowns: $($targets.Count)" -RepoRoot $RepoRoot -LogPath $logPath

    foreach ($mdRel in $targets) {
        $mdAbs = Join-Path $RepoRoot ($mdRel -replace '/', '\')
        if (-not (Test-Path -LiteralPath $mdAbs)) {
            Write-Log -Message "WARN: missing .md -> $mdRel" -RepoRoot $RepoRoot -LogPath $logPath
            continue
        }

        $orig    = Get-Content -LiteralPath $mdAbs -Raw
        $result  = Rewrite-MarkdownContent -Content $orig -Cfg $Cfg
        $updated = $result[0]
        $changed = [int]$result[1]

        if ($changed -gt 0 -and $updated -ne $orig) {
            Write-Log -Message "REWRITE(md): $mdRel (changes=$changed)" -RepoRoot $RepoRoot -LogPath $logPath
            if (-not $dry) {
                Set-Content -LiteralPath $mdAbs -Value $updated -Encoding UTF8
                & $GitExe add -- "$mdRel"
            }
        } else {
            Write-Log -Message "SKIP(md): $mdRel (no change needed)" -RepoRoot $RepoRoot -LogPath $logPath
        }
    }

    Write-Log -Message 'END RewriteMdLinks (OK)' -RepoRoot $RepoRoot -LogPath $logPath
}

try { Main } catch {
    Write-Log -Message ("ERROR(RewriteMdLinks): " + $_.Exception.Message) -RepoRoot $RepoRoot -LogPath ($Cfg['LOG_PATH']) -ConsoleOnly
    throw
}
