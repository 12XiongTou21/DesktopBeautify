# =============================================================================
#  DesktopBeautify / push-to-github.ps1
#  把本项目一键推送到你的 GitHub 仓库（首次开源用）
# -----------------------------------------------------------------------------
#  用法：
#    1) 在 GitHub 网页上先建好一个空仓库（例如 DesktopBeautify），不要勾选自动生成 README
#    2) 右键“以管理员身份运行 PowerShell”，cd 到项目目录，执行：
#         Set-ExecutionPolicy -Scope Process Bypass -Force
#         .\push-to-github.ps1
#    3) 按提示输入 GitHub 用户名；首次 push 会弹出浏览器登录（Git Credential Manager）
# =============================================================================

$ErrorActionPreference = 'Stop'
$Root = $PSScriptRoot

function Write-Step { param([string]$m) Write-Host "`n==> $m" -ForegroundColor Cyan }
function Write-OK   { param([string]$m) Write-Host "    [OK] $m" -ForegroundColor Green }

# 1. 检查 git，没有就用 winget 装
Write-Step '检查 git'
$git = Get-Command git -ErrorAction SilentlyContinue
if (-not $git) {
    Write-Host '    未检测到 git，尝试用 winget 安装 Git.Git ...'
    winget install --id Git.Git -e --silent --accept-source-agreements --accept-package-agreements
    # 刷新当前会话 PATH
    $env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User') + ';' + $env:Path
    $git = Get-Command git -ErrorAction SilentlyContinue
    if (-not $git) { throw 'git 安装失败，请手动安装 Git for Windows 后重试' }
}
Write-OK ("git " + (git --version))

# 2. 询问用户名 / 仓库名
Write-Step 'GitHub 仓库信息'
$gitUser = Read-Host '请输入你的 GitHub 用户名'
if (-not $gitUser) { throw '用户名不能为空' }
$repoName = Read-Host '仓库名（直接回车默认 DesktopBeautify）'
if (-not $repoName) { $repoName = 'DesktopBeautify' }
$remoteUrl = "https://github.com/$gitUser/$repoName.git"
Write-Host ("    将推送到: " + $remoteUrl) -ForegroundColor Yellow

# 3. 配置 git 身份（没有才写）
Write-Step '配置 git 身份'
$gn = git config --global user.name 2>&1
if (-not $gn) { git config --global user.name $gitUser }
$ge = git config --global user.email 2>&1
if (-not $ge) { git config --global user.email "$gitUser@users.noreply.github.com" }

# 4. 初始化 + 提交
Write-Step '初始化并提交'
if (-not (Test-Path (Join-Path $Root '.git'))) {
    git -C $Root init -b main 2>&1 | Out-Null
}
git -C $Root add -A 2>&1 | Out-Null
git -C $Root commit -m "Initial commit: DesktopBeautify Windows 桌面美化一键自动化" 2>&1 | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host '    （无新改动可提交，继续推送）' }

# 5. 设置 remote 并推送
Write-Step '推送'
git -C $Root remote remove origin 2>&1 | Out-Null
git -C $Root remote add origin $remoteUrl 2>&1 | Out-Null
git -C $Root push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Host '    普通推送失败（远端可能已有提交），尝试强制推送 ...' -ForegroundColor Yellow
    git -C $Root push -u -f origin main
    if ($LASTEXITCODE -ne 0) { throw '推送失败，请检查仓库地址 / 网络 / 登录权限' }
}

Write-Host ''
Write-Host '============================================================' -ForegroundColor Green
Write-Host ("  完成！仓库地址: https://github.com/" + $gitUser + "/" + $repoName) -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Green
