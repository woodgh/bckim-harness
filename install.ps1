# bckim-harness 설치 스크립트 (Windows)
#
# 저장소 파일을 각 에이전트 설정 폴더에 연결한다. 여러 번 실행해도 안전하다.
#   powershell -ExecutionPolicy Bypass -File install.ps1             설치
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Uninstall  이 저장소에 연결된 것만 지운다
#
# 연결 방식
#   폴더(스킬, 규칙): 디렉터리 정션. 관리자 권한 없이 만들 수 있다
#   파일(기본 지침):  심볼릭 링크를 먼저 시도하고, 권한이 없으면
#                     Claude Code는 "@<경로>" 가져오기 한 줄짜리 CLAUDE.md, Codex·Gemini는 복사본을 만든다.
#                     복사본은 git pull 뒤 이 스크립트를 다시 실행해야 갱신된다
# 이미 다른 파일이 있으면 덮어쓰지 않고 건너뛴 뒤 마지막에 알린다.
# 이 파일은 Windows PowerShell 5.1이 한글을 읽도록 BOM이 있는 UTF-8로 저장한다.

param([switch]$Uninstall)

$ErrorActionPreference = 'Stop'

$H = (Resolve-Path $PSScriptRoot).Path.TrimEnd('\')
$UserHome = $env:USERPROFILE
$Canonical = Join-Path $UserHome 'orca\bckim-harness'
# 이 스크립트가 복사하거나 만든 파일 목록. 다시 실행할 때 갱신하고, 제거할 때 지운다
$Manifest = Join-Path $UserHome '.bckim-harness-installed.txt'

$script:Linked = 0
$script:Already = 0
$script:Removed = 0
$script:Skipped = New-Object System.Collections.Generic.List[string]
$script:Owned = New-Object System.Collections.Generic.List[string]
if (Test-Path $Manifest) {
    foreach ($line in Get-Content $Manifest -Encoding UTF8) {
        if ($line.Trim() -ne '') { $script:Owned.Add($line.Trim()) }
    }
}

function Normalize([string]$p) {
    return $p.Replace('/', '\').TrimEnd('\').ToLowerInvariant()
}

function Get-LinkTarget($item) {
    if ($null -eq $item.LinkType) { return $null }
    $t = @($item.Target)[0]
    if ($null -eq $t) { return $null }
    return ([string]$t).Replace('\??\', '')
}

function Ensure-Parent([string]$path) {
    $parent = Split-Path $path -Parent
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
}

# 폴더 연결: 디렉터리 정션
function Link-Dir([string]$target, [string]$path) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ($Uninstall) {
        if ($item -and (Normalize (Get-LinkTarget $item)) -eq (Normalize $target)) {
            # 정션만 지우고 대상 폴더는 건드리지 않는다
            [System.IO.Directory]::Delete($path)
            $script:Removed++
            Write-Host "  지움      $path"
        }
        return
    }
    if ($item) {
        $current = Get-LinkTarget $item
        if ($current -and (Normalize $current) -eq (Normalize $target)) { $script:Already++; return }
        if ($current) { $script:Skipped.Add("$path (다른 곳을 가리키는 연결: $current)") }
        else { $script:Skipped.Add("$path (이미 있는 폴더)") }
        return
    }
    Ensure-Parent $path
    New-Item -ItemType Junction -Path $path -Target $target | Out-Null
    $script:Linked++
    Write-Host "  연결      $path"
}

# 파일 연결: 심볼릭 링크, 안 되면 대체 방식
#   $Fallback = 'import' : "@<대상 경로>" 한 줄 (Claude Code CLAUDE.md)
#   $Fallback = 'copy'   : 내용 복사
function Link-File([string]$target, [string]$path, [string]$Fallback) {
    $item = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    $owned = $script:Owned.Contains($path)

    if ($Uninstall) {
        if ($item -and (Normalize (Get-LinkTarget $item)) -eq (Normalize $target)) {
            Remove-Item -LiteralPath $path -Force
            $script:Removed++
            Write-Host "  지움      $path"
        }
        elseif ($item -and $owned) {
            Remove-Item -LiteralPath $path -Force
            $script:Removed++
            Write-Host "  지움      $path"
        }
        return
    }

    $importLine = '@' + $target.Replace('\', '/')
    if ($item) {
        $current = Get-LinkTarget $item
        if ($current -and (Normalize $current) -eq (Normalize $target)) { $script:Already++; return }
        if (-not $current -and $owned) {
            # 이전에 이 스크립트가 만든 대체 파일: 최신 내용으로 다시 쓴다
            if ($Fallback -eq 'import') { [System.IO.File]::WriteAllText($path, $importLine + "`n") }
            else { Copy-Item -LiteralPath $target -Destination $path -Force }
            $script:Already++
            return
        }
        if ($current) { $script:Skipped.Add("$path (다른 곳을 가리키는 링크: $current)") }
        else { $script:Skipped.Add("$path (이미 있는 파일)") }
        return
    }

    Ensure-Parent $path
    try {
        New-Item -ItemType SymbolicLink -Path $path -Target $target -ErrorAction Stop | Out-Null
        Write-Host "  연결      $path"
    }
    catch {
        if ($Fallback -eq 'import') {
            [System.IO.File]::WriteAllText($path, $importLine + "`n")
            Write-Host "  연결      $path (가져오기 한 줄)"
        }
        else {
            Copy-Item -LiteralPath $target -Destination $path -Force
            Write-Host "  복사      $path (git pull 뒤 다시 실행해야 갱신됨)"
        }
        $script:Owned.Add($path)
    }
    $script:Linked++
}

Write-Host "bckim-harness: $H"
if ($Uninstall) { Write-Host '연결을 지웁니다.' } else { Write-Host '연결합니다.' }

# 0. 스킬·기본 지침은 규칙 파일을 ~/orca/bckim-harness/ 로 가리킨다. 다른 곳에 받았으면 그 경로를 정션으로 만든다
if ((Normalize $H) -ne (Normalize $Canonical)) {
    Write-Host '[경로]'
    Link-Dir $H $Canonical
}

# 1. Claude Code
Write-Host '[Claude Code]'
$claude = Join-Path $UserHome '.claude'
Link-File (Join-Path $H 'AGENTS.md') (Join-Path $claude 'CLAUDE.md') 'import'
# 규칙은 폴더째 연결한다. Claude Code는 ~/.claude/rules/ 아래를 하위 폴더까지 읽는다
Link-Dir (Join-Path $H 'rules') (Join-Path $claude 'rules\bckim')
Link-Dir $H (Join-Path $claude 'skills\bckim')

# 2. Codex: 기본 지침은 ~/.codex(또는 CODEX_HOME)와 Orca가 관리하는 계정 폴더마다, 스킬은 ~/.agents/skills
Write-Host '[Codex]'
$codexHomes = New-Object System.Collections.Generic.List[string]
$codexHomes.Add((Join-Path $UserHome '.codex'))
if ($env:CODEX_HOME) { $codexHomes.Add($env:CODEX_HOME) }
# Orca의 Codex 계정 폴더. macOS의 ~/Library/Application Support/orca 에 해당하는 Windows 위치(%APPDATA%\orca)를 가정한다
$orcaAccounts = Join-Path $env:APPDATA 'orca\codex-accounts'
if (Test-Path $orcaAccounts) {
    foreach ($acct in Get-ChildItem -LiteralPath $orcaAccounts -Directory) {
        $acctHome = Join-Path $acct.FullName 'home'
        if (Test-Path $acctHome) { $codexHomes.Add($acctHome) }
    }
}
$seen = @{}
foreach ($ch in $codexHomes) {
    $key = Normalize $ch
    if ($seen.ContainsKey($key)) { continue }
    $seen[$key] = $true
    Link-File (Join-Path $H 'AGENTS.md') (Join-Path $ch 'AGENTS.md') 'copy'
}
foreach ($skill in Get-ChildItem -LiteralPath (Join-Path $H 'skills') -Directory) {
    if (-not (Test-Path (Join-Path $skill.FullName 'SKILL.md'))) { continue }
    Link-Dir $skill.FullName (Join-Path $UserHome ".agents\skills\$($skill.Name)")
}

# 3. Gemini CLI
Write-Host '[Gemini CLI]'
Link-File (Join-Path $H 'AGENTS.md') (Join-Path $UserHome '.gemini\GEMINI.md') 'copy'
if (Get-Command gemini -ErrorAction SilentlyContinue) {
    # 외부 명령의 오류 출력 때문에 스크립트가 멈추지 않게 한다 (Windows PowerShell 5.1)
    $ErrorActionPreference = 'Continue'
    if ($Uninstall) {
        & gemini extensions uninstall bckim *> $null
        if ($LASTEXITCODE -eq 0) { Write-Host '  지움      Gemini 확장 bckim' }
    }
    elseif ((& gemini extensions list 2>$null | Out-String) -match 'bckim') {
        $script:Already++
    }
    else {
        'y' | & gemini extensions link $H *> $null
        if ($LASTEXITCODE -eq 0) { $script:Linked++; Write-Host '  연결      Gemini 확장 bckim' }
        else { $script:Skipped.Add("Gemini 확장 (gemini extensions link 실패. 직접 실행: gemini extensions link $H)") }
    }
    $ErrorActionPreference = 'Stop'
}
else {
    Write-Host '  gemini가 없어 확장 연결은 건너뜁니다.'
}

# 이 스크립트가 만든 대체 파일 목록 저장
if ($Uninstall) {
    if (Test-Path $Manifest) { Remove-Item -LiteralPath $Manifest -Force }
}
elseif ($script:Owned.Count -gt 0) {
    [System.IO.File]::WriteAllLines($Manifest, [string[]]($script:Owned | Select-Object -Unique))
}

Write-Host ''
if ($Uninstall) {
    Write-Host "지운 연결 $($script:Removed)개."
}
else {
    Write-Host "새로 연결 $($script:Linked)개, 이미 연결됨 $($script:Already)개, 건너뜀 $($script:Skipped.Count)개."
    if ($script:Skipped.Count -gt 0) {
        Write-Host '건너뛴 항목 (내용을 확인하고 옮긴 뒤 다시 실행하세요):'
        foreach ($s in $script:Skipped) { Write-Host "  - $s" }
    }
    Write-Host 'Claude Code가 실행 중이면 /reload-plugins, Codex·Gemini는 새 세션부터 적용됩니다.'
}
