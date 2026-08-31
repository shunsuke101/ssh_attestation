<#
.SYNOPSIS
    /collect を実行し、成果物を GitHub に push する（週次自動実行用）。

.DESCRIPTION
    Windows タスク スケジューラから毎週月曜に呼ばれる。

    設計方針: エージェントに git を触らせない。
    claude は収集とファイル書き込みだけを行い、pull / commit / push は
    このスクリプトが決定論的に実行する。そのため claude は次の 4 つをセットで付ける。

      --restricted
          Bash/PowerShell/REPL を丸ごと外す。あわせて WebFetch も外れ、
          ファイル操作はワーキングディレクトリ内に限定され、
          プロジェクトの .claude/settings.json は無視される。
      --tools "Read,Write,Edit,Glob,Grep,WebSearch,WebFetch"
          --restricted が外した WebFetch を明示的に戻す。
          コマンド実行系は戻さない。
      --settings scripts\automation-settings.json
          --restricted は settings ファイルを無視するが、--settings で
          明示したものだけは適用される。ここで権限を与える。
      --permission-mode acceptEdits
          無人実行では権限プロンプトに答えられないため。

    注意: --permission-mode bypassPermissions は --restricted と併用できない
    （"bypassPermissions not supported in restricted mode" で起動に失敗する）。

    この構成では、影響範囲はリポジトリ内のファイル書き込みと Web の読み取りに限られる。

    リポジトリルートは $PSScriptRoot から相対で解決するため、
    フォルダ名が変わっても動く。

.NOTES
    手動実行:  powershell -NoProfile -ExecutionPolicy Bypass -File scripts\weekly-collect.ps1
    ログ:      logs\collect-<日付>.log / logs\last-run.txt
#>

[CmdletBinding()]
param(
    # 収集カテゴリ。省略時は全カテゴリ。
    [ValidateSet('', 'papers', 'specs', 'impl', 'industry')]
    [string]$Category = '',

    # claude を実行せず、git の前処理だけ試す（動作確認用）。
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# ---------------------------------------------------------------- 準備

$RepoRoot = Split-Path -Parent $PSScriptRoot
$LogDir   = Join-Path $RepoRoot 'logs'
$Today    = Get-Date -Format 'yyyy-MM-dd'
$LogFile  = Join-Path $LogDir "collect-$Today.log"
$LastRun  = Join-Path $LogDir 'last-run.txt'

if (-not (Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir -Force | Out-Null }

function Write-Log {
    param([string]$Message, [string]$Level = 'INFO')
    $line = "[{0}] [{1}] {2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Write-Host $line
    Add-Content -Path $LogFile -Value $line -Encoding utf8
}

function Save-LastRun {
    param([string]$Status, [int]$ExitCode, [string]$Commit = '')
    @(
        "last_run  : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "status    : $Status"
        "exit_code : $ExitCode"
        "commit    : $(if ($Commit) { $Commit } else { '(コミットなし)' })"
        "log       : $LogFile"
    ) | Set-Content -Path $LastRun -Encoding utf8
}

# タスク スケジューラのコンテキストでは PATH が最小限のことがあるため、
# 対話シェルと同じ PATH を明示的に組み立てる。
$env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
            [Environment]::GetEnvironmentVariable('Path', 'User')

Write-Log "=========================================================="
Write-Log "週次収集を開始します"
Write-Log "リポジトリ: $RepoRoot"

Set-Location $RepoRoot

# ------------------------------------------------- 前提チェック

foreach ($cmd in @('git', 'claude')) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if (-not $found) {
        Write-Log "$cmd が PATH に見つかりません。中止します。" 'ERROR'
        Save-LastRun -Status "$cmd が見つからない" -ExitCode 127
        exit 127
    }
    Write-Log "$cmd : $($found.Source)"
}

if ((git rev-parse --is-inside-work-tree 2>$null) -ne 'true') {
    Write-Log "git リポジトリではありません。中止します。" 'ERROR'
    Save-LastRun -Status 'git リポジトリでない' -ExitCode 1
    exit 1
}

# ------------------------------------------------- 1. 未コミットの変更を先に退避

# 手で編集して commit し忘れた変更が残っていると pull --rebase が失敗する。
# そこで中止すると週次実行がまるごと失われるので、先に別コミットとして保存する。
# 収集結果とは別のコミットに分けることで、履歴上どちらの変更か区別できる。
$pending = git status --porcelain
if ($pending) {
    Write-Log "未コミットの変更があります。収集の前に別コミットとして保存します。" 'WARN'
    $pending | ForEach-Object { Write-Log "  $_" }

    git add -A
    git commit -m "wip: 週次自動実行の前に未コミットの変更を保存

scripts/weekly-collect.ps1 が自動実行前に検出した変更。
手作業の途中だった場合は、内容を確認して必要なら整理すること。"

    if ($LASTEXITCODE -ne 0) {
        Write-Log "退避コミットに失敗しました。中止します。" 'ERROR'
        Save-LastRun -Status '退避コミット失敗' -ExitCode 6
        exit 6
    }
    Write-Log "退避しました: $(git rev-parse HEAD)"
}

# ------------------------------------------------- 2. 先にリモートを取り込む

Write-Log "git pull --rebase を実行します"
$pull = git pull --rebase 2>&1
$pull | ForEach-Object { Write-Log "  git> $_" }

if ($LASTEXITCODE -ne 0) {
    Write-Log "pull に失敗しました。競合の可能性があります。自動解決はせず中止します。" 'ERROR'
    Write-Log "手動で 'git status' を確認してください（rebase 途中なら 'git rebase --abort'）。" 'ERROR'
    Save-LastRun -Status 'git pull 失敗（要手動対応）' -ExitCode 2
    exit 2
}

# 収集前の HEAD。後で「本当に新しいコミットができたか」を判定するのに使う。
$headBefore = git rev-parse HEAD

# ------------------------------------------------- 3. /collect を実行

# --restricted 下ではプロジェクトのスラッシュコマンド (/collect) が解決されない
# （"Unknown command: /collect" となり、しかも exit 0 が返るので気づきにくい）。
# そこでコマンド定義ファイルの中身を読み、そのままプロンプトとして渡す。
# 定義は .claude/commands/collect.md 一箇所のままなので、手動実行との齟齬は生じない。
$commandFile = Join-Path $RepoRoot '.claude\commands\collect.md'
if (-not (Test-Path $commandFile)) {
    Write-Log "コマンド定義 $commandFile が見つかりません。中止します。" 'ERROR'
    Save-LastRun -Status 'collect.md が無い' -ExitCode 8
    exit 8
}

$commandBody = Get-Content $commandFile -Raw -Encoding utf8
# 先頭の YAML frontmatter を除去する
$commandBody = [regex]::Replace($commandBody, '^---\r?\n.*?\r?\n---\r?\n', '', 'Singleline')
# $ARGUMENTS を実際のカテゴリに差し替える
$prompt = $commandBody -replace '\$ARGUMENTS', $Category

Write-Log "プロンプトを .claude/commands/collect.md から構築しました（$($prompt.Length) 文字）"

if ($DryRun) {
    Write-Log "DryRun のため claude は実行しません（実行予定: $prompt）" 'WARN'
    $claudeExit = 0
} else {
    $settingsPath = Join-Path $PSScriptRoot 'automation-settings.json'
    if (-not (Test-Path $settingsPath)) {
        Write-Log "権限設定 $settingsPath が見つかりません。中止します。" 'ERROR'
        Save-LastRun -Status 'automation-settings.json が無い' -ExitCode 7
        exit 7
    }

    # --restricted でコマンド実行系を落とし、--tools で WebFetch だけ戻す。
    # --restricted は .claude/settings.json を無視するため、権限は --settings で渡す。
    $claudeArgs = @(
        '-p', $prompt
        '--restricted'
        '--tools', 'Read,Write,Edit,Glob,Grep,WebSearch,WebFetch'
        '--settings', $settingsPath
        '--permission-mode', 'acceptEdits'
    )

    Write-Log "claude を実行します（カテゴリ: $(if ($Category) { $Category } else { '全て' })）"
    Write-Log "  フラグ: --restricted --tools ... --settings ... --permission-mode acceptEdits"

    # 出力は判定にも使うので変数に溜めつつログへ流す
    $claudeOut = & claude @claudeArgs 2>&1 | ForEach-Object {
        Write-Log "  claude> $_"
        $_
    }
    $claudeExit = $LASTEXITCODE

    # claude はプロンプト解決に失敗しても exit 0 を返すことがある
    # （例: "Unknown command: /collect"）。終了コードだけを信用しない。
    $outText = ($claudeOut | Out-String)
    if ($outText -match 'Unknown command|^Error:|not supported in restricted mode') {
        Write-Log "claude の出力に失敗を示す文字列が含まれています。収集は行われていません。" 'ERROR'
        Save-LastRun -Status 'claude がプロンプトを実行できなかった（要確認）' -ExitCode 9
        exit 9
    }

    if ($claudeExit -eq 0) {
        Write-Log "claude が正常終了しました"
    } else {
        Write-Log "claude が異常終了しました (exit=$claudeExit)。書き込み済みの変更はコミットします。" 'WARN'
    }
}

# ------------------------------------------------- 4. 変更を判定

$changes = git status --porcelain
if (-not $changes) {
    Write-Log "変更なし（新着なし）。コミットせず終了します。"
    Save-LastRun -Status '新着なし' -ExitCode $claudeExit
    exit $claudeExit
}

Write-Log "以下の変更を検出しました:"
$changes | ForEach-Object { Write-Log "  $_" }

# ------------------------------------------------- 5. コミットして push

git add -A
if ($LASTEXITCODE -ne 0) {
    Write-Log "git add に失敗しました。" 'ERROR'
    Save-LastRun -Status 'git add 失敗' -ExitCode 3
    exit 3
}

$summary = if ($claudeExit -eq 0) { "" } else { "`n`n※ claude が異常終了 (exit=$claudeExit)。内容を確認してください。" }
$message = "collect: $Today の自動収集$summary`n`nscripts/weekly-collect.ps1 による週次自動実行。"

git commit -m $message
if ($LASTEXITCODE -ne 0) {
    Write-Log "git commit に失敗しました。" 'ERROR'
    Save-LastRun -Status 'git commit 失敗' -ExitCode 4
    exit 4
}

$headAfter = git rev-parse HEAD
Write-Log "コミットしました: $headAfter"

Write-Log "git push を実行します"
$push = git push 2>&1
$push | ForEach-Object { Write-Log "  git> $_" }

if ($LASTEXITCODE -ne 0) {
    Write-Log "push に失敗しました。コミットはローカルに残っています。" 'ERROR'
    Write-Log "SSH 鍵とネットワークを確認し、手動で 'git push' してください。" 'ERROR'
    Save-LastRun -Status 'git push 失敗（コミットはローカルに存在）' -ExitCode 5 -Commit $headAfter
    exit 5
}

Write-Log "push まで完了しました ($headBefore -> $headAfter)"
Save-LastRun -Status '成功' -ExitCode $claudeExit -Commit $headAfter
Write-Log "=========================================================="

exit $claudeExit
