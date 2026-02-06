<#
.SYNOPSIS
  Outlookの既定アカウントの表示名（EX優先）とSMTPを取得し、git --global の user.name / user.email を設定します。

.DESCRIPTION
  - 表示名は優先順で取得：ExchangeUser.Name > Account.DisplayName > Session.CurrentUser.Name
  - user.name は「表示名_(USERNAME)」形式（USERNAMEが空ならUSERPROFILE末尾にフォールバック）
  - user.email は Outlook COM から既定アカウントの SMTP を取得
  - Git は PATH 不要。PortableGit（%USERPROFILE%\Software\PortableGit\cmd\git.exe）を含む代表的場所を探索
  - DryRun で「実行せずに内容のみ表示」可能
  - 失敗時の throw メッセージに代替・回避コマンドを内包（エラーID付き、PS 5.1互換表記）

.PARAMETER NameOverride
  形式を含めて明示的に user.name を指定したい場合に使用。指定があれば自動組み立てより優先。

.PARAMETER DryRun
  実行せず、設定予定の値とコマンドのみ表示します。
#>

[CmdletBinding()]
param(
    [string]$NameOverride,
    [switch]$DryRun
)

# --- Git 実行ファイルの探索（PS 5.1互換） ---
function Find-GitExe {
    [CmdletBinding()]
    param()

    # PATH上のgit.exe
    $cmd = Get-Command git.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Path) { return $cmd.Path }

    # 代表的な探索パス
    $candidates = @(
        (Join-Path $env:USERPROFILE 'Software\PortableGit\cmd\git.exe'),
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe')
    )

    foreach ($p in $candidates) {
        if ($p -and (Test-Path $p)) { return $p }
    }

    $msg = @'
[E100] git.exe が見つかりません。
目的: git --global に name/email を設定する。

回避コマンド例（いずれか）:
1) ポータブル版のフルパスで直接実行
   $git = "$env:USERPROFILE\Software\PortableGit\cmd\git.exe"
   & $git config --global user.name  "表示名_(USERNAME)"
   & $git config --global user.email "user@example.com"

2) 一時的に PATH を通す
   $env:PATH = "$env:USERPROFILE\Software\PortableGit\cmd;$env:PATH"
   git config --global user.name  "表示名_(USERNAME)"
   git config --global user.email "user@example.com"

3) 現在のグローバル設定の確認
   & "$env:USERPROFILE\Software\PortableGit\cmd\git.exe" config --global --list --show-origin
'@
    throw $msg
}

# --- Outlook から既定アカウントの SMTP と表示名（EX優先）を取得 ---
function Get-OutlookIdentity {
    [CmdletBinding()]
    param()

    # Outlook.Application を取得/起動
    $ol = $null
    try {
        $ol = [Runtime.InteropServices.Marshal]::GetActiveObject("Outlook.Application")
    } catch {
        try { $ol = New-Object -ComObject Outlook.Application } catch {
            $msg = @'
[E200] Outlook.Application を作成/取得できませんでした。
原因候補: Outlook未インストール/未構成、プロファイルなし、COM起動不可。

目的: user.email を正しく設定する。

回避コマンド例:
A) メールアドレスを明示指定（最短）
   git config --global user.email "user@example.com"

B) ドメイン参加環境なら AD から代替取得
   Import-Module ActiveDirectory
   $u = Get-ADUser "$env:USERDOMAIN\$env:USERNAME" -Properties mail,proxyAddresses
   $smtpPrimary = $null
   if ($u -and $u.proxyAddresses) {
     $smtpPrimary = ($u.proxyAddresses | Where-Object { $_ -match '^SMTP:' } | ForEach-Object { $_.Substring(5) } | Select-Object -First 1)
   }
   $smtpSecondary = $null
   if (-not $smtpPrimary -and $u -and $u.proxyAddresses) {
     $smtpSecondary = ($u.proxyAddresses | Where-Object { $_ -match '^smtp:' } | ForEach-Object { $_.Substring(5) } | Select-Object -First 1)
   }
   $email = if ($u.mail) { $u.mail } elseif ($smtpPrimary) { $smtpPrimary } elseif ($smtpSecondary) { $smtpSecondary } else { $null }
   if ($email) { git config --global user.email $email } else { Write-Error "メール取得不可" }

C) Outlookを起動してプロファイル構成を完了 → スクリプト再実行
'@
            throw $msg
        }
    }

    $session  = $ol.Session
    $accounts = @()
    if ($session -and $session.Accounts) { foreach ($a in $session.Accounts) { $accounts += $a } }

    if (-not $accounts -or $accounts.Count -eq 0) {
        $msg = @'
[E210] Outlookプロファイルにアカウントが見つかりませんでした。
原因候補: 既定プロファイル未設定、プロファイル破損、初期化未完了。

目的: 表示名・SMTPの取得。

回避コマンド例:
A) 表示名不明として OS ユーザー名で代替し、メールは明示指定
   $uname = $env:USERNAME; if (-not $uname) { $uname = Split-Path -Leaf $env:USERPROFILE }
   $name  = "表示名不明_($uname)"
   git config --global user.name  $name
   git config --global user.email "user@example.com"

B) Outlookを起動してプロファイルを作成 → 本スクリプトを再実行
'@
        throw $msg
    }

    # 既定アカウント（先頭）を優先
    $primary = $accounts | Select-Object -First 1

    # --- ExchangeUser を最優先で取得（氏名の精度向上） ---
    $exu = $null
    if ($session -and $session.CurrentUser -and $session.CurrentUser.AddressEntry) {
        try {
            $ae = $session.CurrentUser.AddressEntry
            if ($ae.Type -eq "EX") { $exu = $ae.GetExchangeUser() }
        } catch { $exu = $null }
    }

    # 表示名の取得優先順位: ExchangeUser.Name > Account.DisplayName > CurrentUser.Name
    $displayName = $null
    if ($exu -and $exu.Name) {
        $displayName = $exu.Name
    } elseif ($primary -and ($primary.PSObject.Properties.Name -contains 'DisplayName') -and $primary.DisplayName) {
        $displayName = $primary.DisplayName
    } elseif ($session -and $session.CurrentUser -and $session.CurrentUser.Name) {
        $displayName = $session.CurrentUser.Name
    }

    # SMTP アドレスの取得（既定アカウント優先 → 他アカウント → CurrentUser 解決）
    $smtp = $null
    if ($primary -and ($primary.PSObject.Properties.Name -contains 'SmtpAddress') -and $primary.SmtpAddress) {
        $smtp = $primary.SmtpAddress
    } else {
        foreach ($acct in $accounts) {
            if (($acct.PSObject.Properties.Name -contains 'SmtpAddress') -and $acct.SmtpAddress) {
                $smtp = $acct.SmtpAddress; break
            }
        }
        if (-not $smtp -and $session -and $session.CurrentUser -and $session.CurrentUser.AddressEntry) {
            try {
                $ae2 = $session.CurrentUser.AddressEntry
                if ($ae2.Type -eq "EX") {
                    $ex2 = $ae2.GetExchangeUser()
                    if ($ex2 -and $ex2.PrimarySmtpAddress) { $smtp = $ex2.PrimarySmtpAddress }
                } elseif ($ae2.Type -eq "SMTP" -and $ae2.Address) {
                    $smtp = $ae2.Address
                }
            } catch {}
        }
    }

    if (-not $displayName -or $displayName.Trim().Length -eq 0) {
        $msg = @'
[E220] Outlookの表示名を取得できませんでした。
目的: user.name = 「表示名_(USERNAME)」を設定する。

回避コマンド例（表示名を手動指定）:
   $uname = $env:USERNAME; if (-not $uname) { $uname = Split-Path -Leaf $env:USERPROFILE }
   $disp  = "久保川 一良"  # 任意の表示名
   $name  = "${disp}_(${uname})"
   git config --global user.name $name
'@
        throw $msg
    }
    if (-not $smtp -or $smtp.Trim().Length -eq 0) {
        $msg = @'
[E230] SMTPアドレスの自動特定に失敗しました（既定アカウントにSMTPが割り当てられていない可能性）。
目的: user.email を設定する。

回避コマンド例:
A) SMTP を手動指定（最短）
   git config --global user.email "user@example.com"

B) CurrentUser からの強制解決スニペット（検査用）
   $ol = New-Object -ComObject Outlook.Application
   $ae = $ol.Session.CurrentUser.AddressEntry
   try {
     if ($ae.Type -eq "EX") { $email = $ae.GetExchangeUser().PrimarySmtpAddress }
     elseif ($ae.Type -eq "SMTP") { $email = $ae.Address }
   } catch {}
   $email
'@
        throw $msg
    }

    # Git に必要な最小情報のみ返却
    [PSCustomObject]@{
        DisplayName = $displayName
        SmtpAddress = $smtp
    }
}

# --- OS側ユーザー名の決定（USERNAME 優先、PROFILE 末尾にフォールバック） ---
function Get-OsUserNameForSuffix {
    [CmdletBinding()]
    param()

    $uname = $env:USERNAME
    if ($uname -and $uname.Trim().Length -gt 0) { return $uname }

    if ($env:USERPROFILE) {
        $leaf = Split-Path -Leaf $env:USERPROFILE
        if ($leaf -and $leaf.Trim().Length -gt 0) { return $leaf }
    }

    $msg = @'
[E300] OSユーザー名の決定に失敗しました（USERNAME/USERPROFILE とも空）。
目的: user.name を設定する。

回避コマンド例（明示指定）:
   git config --global user.name "表示名_(KUBOKAWA)"
'@
    throw $msg
}

# --- user.name の組み立て（表示名_(USERNAME)） ---
function Build-GitUserName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$DisplayName,
        [Parameter(Mandatory)] [string]$OsUserName,
        [string]$Override
    )

    if ($Override) { return $Override }
    return "${DisplayName}_(${OsUserName})"
}

# --- 実行（DryRun対応） ---
function Set-GitGlobalIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$GitExe,
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [string]$Email,
        [switch]$DryRun
    )

    $commands = @(
        @($GitExe, 'config', '--global', 'user.name',  $Name),
        @($GitExe, 'config', '--global', 'user.email', $Email)
    )

    Write-Host "設定予定: user.name = '$Name'" -ForegroundColor Cyan
    Write-Host "設定予定: user.email = '$Email'" -ForegroundColor Cyan
    Write-Host "Git 実行ファイル: $GitExe" -ForegroundColor DarkGray

    if ($DryRun) {
        Write-Host "[DryRun] 実行せずに内容のみ表示します。" -ForegroundColor Yellow
        foreach ($cmd in $commands) { Write-Host ('> ' + ($cmd -join ' ')) }
        return
    }

    foreach ($cmd in $commands) {
        & $cmd[0] $cmd[1..($cmd.Count-1)]
        if ($LASTEXITCODE -ne 0) {
            $msg = @'
[E400] Gitコマンドに失敗しました（git config --global 実行時）。
原因候補: グローバル設定ファイルへの書き込み権限なし、HOME 判定の問題、Git実体の不整合。

目的: name/email を確実に保存する。

回避コマンド例:
1) ユーザースコープの HOME を明示して再実行
   $env:HOME = $env:USERPROFILE
   & "$GitExe" config --global user.name  "$Name"
   & "$GitExe" config --global user.email "$Email"

2) --global をやめてローカルリポジトリに設定（権限回避・プロジェクト限定）
   cd C:\path\to\repo
   & "$GitExe" config user.name  "$Name"
   & "$GitExe" config user.email "$Email"

3) 現在値の確認／設定ファイルの場所確認
   & "$GitExe" config --global --get user.name
   & "$GitExe" config --global --get user.email
   & "$GitExe" config --global --list --show-origin
'@
            throw $msg
        }
    }

    Write-Host "完了：git --global の name/email を更新しました。" -ForegroundColor Green
}

# --- メイン処理 ---
try {
    $git   = Find-GitExe

    $outId = Get-OutlookIdentity
    $disp  = $outId.DisplayName
    $email = $outId.SmtpAddress

    $osUser = Get-OsUserNameForSuffix
    $name   = Build-GitUserName -DisplayName $disp -OsUserName $osUser -Override $NameOverride

    Set-GitGlobalIdentity -GitExe $git -Name $name -Email $email -DryRun:$DryRun

} catch {
    Write-Error $_.Exception.Message
    exit 1
}
