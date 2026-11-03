# =============================================================================
#  desktop-beautify / verify.ps1
#  安装前可行性检查（只读检查，不做任何安装/修改）
# -----------------------------------------------------------------------------
#  检查内容：
#    1) 目录结构与必需文件是否齐全
#    2) 三个软件是否已安装
#    3) TranslucentTB.settings.json 是否合法
#    4) nexus_config.reg 是否合法
#    5) winget 是否可用（离线缺包时的兜底）
#    6) 皮肤下载地址是否可访问（联网检查）
#  退出码：0 = 全部就绪；1 = 有缺项
# =============================================================================

$ErrorActionPreference = 'SilentlyContinue'
$Root        = $PSScriptRoot
$SoftwareDir = Join-Path $Root 'Software'
$SkinsDir    = Join-Path $Root 'Skins'
$DepsDir     = Join-Path $SoftwareDir 'Dependencies'
$ConfigDir   = Join-Path $Root 'config'

$issues = @()
$okays  = @()

function Check { param([bool]$cond, [string]$ok, [string]$fail)
    if ($cond) { $okays += $ok; Write-Host "  [OK] $ok" -ForegroundColor Green }
    else       { $issues += $fail; Write-Host "  [XX] $fail" -ForegroundColor Red }
}

Write-Host ''
Write-Host '=== 桌面美化 可行性预检 ===' -ForegroundColor Cyan

# 1. 必需文件
Write-Host '`n[1] 必需文件' -ForegroundColor Cyan
$req = @(
    (Join-Path $SoftwareDir 'Rainmeter_4.5.28.3936_Machine_X86_nullsoft_en-US.exe'),
    (Join-Path $SoftwareDir 'TranslucentTB_2026.2.0.0_X64_msix_zh-CN.msix'),
    (Join-Path $SoftwareDir 'NexusSetup\NexusSetup.exe'),
    (Join-Path $DepsDir 'Microsoft.UI.Xaml_8.2310.30001.0_X64_msix_en-US.msix'),
    (Join-Path $DepsDir 'Microsoft Visual C++ 2015 UWP Desktop Runtime Package_14.0.33728.0_X64_msix_en-US.zip'),
    (Join-Path $SkinsDir 'nexus_config.reg'),
    (Join-Path $ConfigDir 'TranslucentTB.settings.json'),
    (Join-Path $Root 'install.ps1'),
    (Join-Path $Root 'run.bat')
)
foreach ($f in $req) {
    Check (Test-Path $f) ("存在: " + (Split-Path $f -Leaf)) ("缺失: " + $f)
}

# 2. 已安装状态
Write-Host '`n[2] 已安装状态' -ForegroundColor Cyan
$rm1 = Join-Path ${env:ProgramFiles} 'Rainmeter\Rainmeter.exe'
$rm2 = Join-Path ${env:ProgramFiles(x86)} 'Rainmeter\Rainmeter.exe'
Check ((Test-Path $rm1) -or (Test-Path $rm2)) 'Rainmeter 已安装' 'Rainmeter 未安装（脚本将安装）'
Check (Test-Path (Join-Path ${env:ProgramFiles} 'Winstep\Nexus.exe')) 'Nexus 已安装' 'Nexus 未安装（脚本将安装）'
$tbt = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq '28017CharlesMilette.TranslucentTB_v826wp6bftszj' }
Check [bool]$tbt 'TranslucentTB 已安装' 'TranslucentTB 未安装（脚本将安装）'

# 3. JSON
Write-Host '`n[3] 配置合法性' -ForegroundColor Cyan
try {
    $j = Get-Content (Join-Path $ConfigDir 'TranslucentTB.settings.json') -Raw | ConvertFrom-Json
    Check ($j.desktop_appearance.accent -eq 'clear') 'TranslucentTB 配置: accent=clear (完全透明)' 'TranslucentTB 配置异常'
} catch {
    Check $false 'TranslucentTB 配置 JSON 合法' "JSON 解析失败: $($_.Exception.Message)"
}
$regHead = Get-Content (Join-Path $SkinsDir 'nexus_config.reg') -TotalCount 1 -ErrorAction SilentlyContinue
Check ($regHead -match 'Windows Registry Editor') 'nexus_config.reg 格式合法' 'nexus_config.reg 格式异常'

# 4. winget
Write-Host '`n[4] 兜底工具' -ForegroundColor Cyan
Check [bool](Get-Command winget -ErrorAction SilentlyContinue) 'winget 可用（缺包时兜底）' 'winget 不可用（离线包必须齐全）'

# 5. 皮肤下载地址连通性
Write-Host '`n[5] 皮肤下载连通性' -ForegroundColor Cyan
$skinUrl = 'https://github.com/marcopixel/Lano-Visualizer/archive/refs/heads/master.zip'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $r = Invoke-WebRequest -Uri $skinUrl -Method Head -TimeoutSec 20 -UseBasicParsing
    Check ($r.StatusCode -lt 400) "皮肤下载可达 (HTTP $($r.StatusCode))" '皮肤下载不可达'
} catch {
    Check $false '皮肤下载可达' "皮肤下载检查失败（可手动放 Skins\Lano-Visualizer.zip）: $($_.Exception.Message)"
}

# 汇总
Write-Host ''
Write-Host '=== 预检结果 ===' -ForegroundColor Cyan
Write-Host ("  通过: " + $okays.Count + " 项")
Write-Host ("  问题: " + $issues.Count + " 项")
if ($issues.Count -gt 0) {
    Write-Host '  缺失/问题项：' -ForegroundColor Yellow
    $issues | ForEach-Object { Write-Host ("    - " + $_) -ForegroundColor Yellow }
    exit 1
} else {
    Write-Host '  全部就绪，可运行 install.ps1 或双击 run.bat。' -ForegroundColor Green
    exit 0
}
