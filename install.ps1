# =============================================================================
#  desktop-beautify / install.ps1
#  桌面美化一键安装脚本 —— 按视频教程参数自动完成
# -----------------------------------------------------------------------------
#  完成内容：
#    1) TranslucentTB   任务栏完全透明
#    2) Rainmeter       部署音频频谱条皮肤（简约频谱，随 QQ音乐 等系统声音跳动）
#    3) Winstep Nexus   安装停靠栏并导入配置 (Skins\nexus_config.reg)
#  不做内容（需手动）：动态壁纸(Wallpaper Engine)、桌面/停靠栏图标、时间插件
# -----------------------------------------------------------------------------
#  用法：
#    右键“以管理员身份运行 PowerShell”：
#        Set-ExecutionPolicy -Scope Process Bypass -Force
#        .\install.ps1
#    或直接双击 run.bat（会自动提权）
# =============================================================================

#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Force      # 已安装的组件也强制重装/重配
)

$ErrorActionPreference = 'Stop'
$ProgressPreference     = 'SilentlyContinue'

# 保证 PowerShell 5.1 能访问 GitHub (TLS 1.2)
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# -----------------------------------------------------------------------------
#  ★ 可配置区（按需修改）★
# -----------------------------------------------------------------------------
# 音频频谱条皮肤（致美化「简约频谱」，AudioLevel 监听系统输出，自动联动 QQ音乐）
# 皮肤文件位于项目 Skins\简约频谱\（主文件 Wave.ini）
$MusicSkin = @{
    ConfigName = '简约频谱'        # Rainmeter 皮肤配置名(文件夹名)
    Ini        = 'Wave.ini'        # 需要加载的主 ini
}
# Rainmeter 皮肤根目录（默认 Documents\Rainmeter\Skins）
$RainmeterSkinsDir = Join-Path $env:USERPROFILE 'Documents\Rainmeter\Skins'

# 是否注册开机自启（Rainmeter + TranslucentTB；Nexus 已在配置里自动运行）
$EnableAutostart = $true
# -----------------------------------------------------------------------------

# ---- 路径 ----
$Root        = $PSScriptRoot
$SoftwareDir = Join-Path $Root 'Software'
$SkinsDir    = Join-Path $Root 'Skins'
$DepsDir     = Join-Path $SoftwareDir 'Dependencies'
$ConfigDir   = Join-Path $Root 'config'
$TempDir     = Join-Path $env:TEMP 'DesktopBeautify'
New-Item -ItemType Directory -Force -Path $TempDir | Out-Null

$RainmeterExe   = Join-Path ${env:ProgramFiles} 'Rainmeter\Rainmeter.exe'
$RainmeterExe86 = Join-Path ${env:ProgramFiles(x86)} 'Rainmeter\Rainmeter.exe'
$NexusSetupExe  = Join-Path $SoftwareDir 'NexusSetup\NexusSetup.exe'
$NexusConfigReg = Join-Path $SkinsDir 'nexus_config.reg'

$TranslucentTBPkg          = '28017CharlesMilette.TranslucentTB_v826wp6bftszj'
$TranslucentTBSettingsDir  = Join-Path $env:LOCALAPPDATA ("Packages\{0}\RoamingState" -f $TranslucentTBPkg)
$TranslucentTBSettings     = Join-Path $TranslucentTBSettingsDir 'settings.json'

# -----------------------------------------------------------------------------
function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-OK   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!!] $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "    [XX] $Msg" -ForegroundColor Red }

function Test-Admin {
    $id = [Security.Principal.WindowsIdentity]::GetCurrent()
    $p  = New-Object Security.Principal.WindowsPrincipal($id)
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-AppxInstalled([string]$PackageFamilyName) {
    return [bool](Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName })
}

# 安装 Appx/Msix（幂等，已安装则跳过）
function Install-Appx([string]$Path, [string]$PackageFamilyName) {
    if (-not $Force -and (Get-AppxInstalled $PackageFamilyName)) {
        Write-OK "已安装 $PackageFamilyName，跳过"
        return
    }
    Write-Host "    安装 $([IO.Path]::GetFileName($Path)) ..."
    Add-AppxPackage -Path $Path -ErrorAction Stop
    Write-OK "已安装 $PackageFamilyName"
}

# 静默安装并等待退出
function Invoke-Silent([string]$Exe, [string[]]$Switches, [string]$Desc) {
    Write-Host "    运行 $Desc ..."
    $p = Start-Process -FilePath $Exe -ArgumentList $Switches -Wait -PassThru
    if ($p.ExitCode -ne 0) { throw "$Desc 退出码 $($p.ExitCode)" }
    Write-OK $Desc
}

# 运行 Rainmeter bang
function Invoke-RainmeterBang([string]$Bang) {
    $exe = $RainmeterExe
    if (-not (Test-Path $exe)) { $exe = $RainmeterExe86 }
    if (-not (Test-Path $exe)) { throw '未找到 Rainmeter.exe' }
    Start-Process -FilePath $exe -ArgumentList $Bang
}

# 启动打包(UWP/MSIX)应用
function Start-PackagedApp([string]$PackageFamilyName) {
    $app = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq $PackageFamilyName } | Select-Object -First 1
    if (-not $app) { Write-Warn "未安装 $PackageFamilyName"; return }
    $appId = (Get-AppxPackageManifest $app).Package.Applications.Application.Id | Select-Object -First 1
    if (-not $appId) { Write-Warn "无法获取 $PackageFamilyName 的 AppId"; return }
    Start-Process 'explorer.exe' -ArgumentList ("shell:AppsFolder\{0}!{1}" -f $PackageFamilyName, $appId)
    Write-OK "已启动 $PackageFamilyName"
}

# -----------------------------------------------------------------------------
Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host '   桌面美化一键安装  (Rainmeter + Nexus + TranslucentTB)' -ForegroundColor Magenta
Write-Host '============================================================' -ForegroundColor Magenta

# 1. 提权
if (-not (Test-Admin)) {
    Write-Warn '需要管理员权限，正在重新以管理员身份启动...（如弹出 UAC 请点“是”）'
    $scriptPath = $PSCommandPath
    if (-not $scriptPath) { $scriptPath = Join-Path $PSScriptRoot 'install.ps1' }
    try {
        Start-Process -FilePath 'powershell.exe' -Verb RunAs `
            -ArgumentList @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $scriptPath))
    } catch {
        Write-Fail '提权失败（可能取消了 UAC）。请右键“以管理员身份运行 PowerShell”后再执行本脚本。'
    }
    exit 0
}
Write-OK '已获取管理员权限'

# 2. 依赖 + TranslucentTB
Write-Step '安装 TranslucentTB 及其依赖 (任务栏透明)'
$vclibsZip = Join-Path $DepsDir 'Microsoft Visual C++ 2015 UWP Desktop Runtime Package_14.0.33728.0_X64_msix_en-US.zip'
$xamlPkg   = Join-Path $DepsDir 'Microsoft.UI.Xaml_8.2310.30001.0_X64_msix_en-US.msix'
$tbtBundle = Join-Path $SoftwareDir 'TranslucentTB_2026.2.0.0_X64_msix_zh-CN.msix'

if (Test-Path $vclibsZip) {
    if (-not (Test-Path (Join-Path $TempDir 'x64\Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64.appx'))) {
        Expand-Archive -Path $vclibsZip -DestinationPath $TempDir -Force
    }
    $vclibsAppx = Join-Path $TempDir 'x64\Microsoft.VCLibs.140.00.UWPDesktop_14.0.33728.0_x64.appx'
    Install-Appx $vclibsAppx 'Microsoft.VCLibs.140.00.UWPDesktop_8wekyb3d8bbwe'
} else {
    Write-Warn '未找到 VCLibs 依赖包，跳过'
}

if (Test-Path $xamlPkg) {
    Install-Appx $xamlPkg 'Microsoft.UI.Xaml.2.8_8wekyb3d8bbwe'
} else {
    Write-Warn '未找到 Microsoft.UI.Xaml 依赖，跳过'
}

if (Test-Path $tbtBundle) {
    # TranslucentTB 文件实为 msixbundle（内容含 AppxBundleManifest），复制为正确扩展名再安装
    $tbtStaged = Join-Path $TempDir 'TranslucentTB.msixbundle'
    Copy-Item $tbtBundle $tbtStaged -Force
    Install-Appx $tbtStaged $TranslucentTBPkg
    New-Item -ItemType Directory -Force -Path $TranslucentTBSettingsDir | Out-Null
    $srcSettings = Join-Path $ConfigDir 'TranslucentTB.settings.json'
    if (Test-Path $srcSettings) {
        Copy-Item $srcSettings $TranslucentTBSettings -Force
        Write-OK '已写入 TranslucentTB 透明配置 (accent=clear)'
    }
} else {
    Write-Warn '未找到 TranslucentTB 安装包，尝试 winget 安装'
    winget install --id CharlesMilette.TranslucentTB --silent --accept-source-agreements --accept-package-agreements
}

# 3. Rainmeter
Write-Step '安装 Rainmeter'
$rainmeterInstaller = Join-Path $SoftwareDir 'Rainmeter_4.5.28.3936_Machine_X86_nullsoft_en-US.exe'
if (Test-Path $rainmeterInstaller) {
    if (-not $Force -and ((Test-Path $RainmeterExe) -or (Test-Path $RainmeterExe86))) {
        Write-OK 'Rainmeter 已安装，跳过'
    } else {
        Invoke-Silent $rainmeterInstaller @('/S') '安装 Rainmeter'
    }
} else {
    Write-Warn '未找到 Rainmeter 安装包，尝试 winget 安装'
    winget install --id Rainmeter.Rainmeter --silent --accept-source-agreements --accept-package-agreements
}

# 4. Nexus Dock
Write-Step '安装 Winstep Nexus Dock'
# Nexus 是 32 位程序，可能装在 Program Files 或 Program Files (x86)，两处都要查
$nexusExe64 = Join-Path ${env:ProgramFiles} 'Winstep\Nexus.exe'
$nexusExe86 = Join-Path ${env:ProgramFiles(x86)} 'Winstep\Nexus.exe'
$nexusInstalled = (Test-Path $nexusExe64) -or (Test-Path $nexusExe86)
if (Test-Path $NexusSetupExe) {
    if (-not $Force -and $nexusInstalled) {
        Write-OK 'Nexus 已安装，跳过'
    } else {
        # 安装前先结束 Nexus/Winstep，否则安装器会因程序占用而失败(退出码1)
        Stop-Process -Name 'Nexus','Winstep','WorkShelf','NextSTART' -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Invoke-Silent $NexusSetupExe @('/SP-','/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART') '安装 Nexus'
    }
    # 先关闭 Nexus，避免它退出时把注册表配置覆盖回去
    Stop-Process -Name 'Nexus' -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    if (Test-Path $NexusConfigReg) {
        reg import $NexusConfigReg | Out-Null
        Write-OK '已导入 Nexus 停靠栏配置 (Skins\nexus_config.reg)'
    } else {
        Write-Warn '未找到 nexus_config.reg，Nexus 使用默认配置'
    }
    # 用注册表精确覆盖滑块无法命中的参数（视频参数：图标40、偏移32、放大68、关闭鼠标经过标签、禁用声音）
    $nxMain  = 'HKCU\Software\WinSTEP2000\NeXuS'
    $nxDocks = 'HKCU\Software\WinSTEP2000\NeXuS\Docks'
    reg add $nxMain  /v DockIconSize1    /t REG_SZ /d '40'    /f | Out-Null
    reg add $nxDocks /v DockIconSize1    /t REG_SZ /d '40'    /f | Out-Null
    reg add $nxDocks /v DockEdgeOffset1  /t REG_SZ /d '32'    /f | Out-Null
    reg add $nxDocks /v DockMagPixels1   /t REG_SZ /d '68'    /f | Out-Null
    reg add $nxMain  /v DockShowLabels1  /t REG_SZ /d 'False' /f | Out-Null
    reg add $nxDocks /v DockShowLabels1  /t REG_SZ /d 'False' /f | Out-Null
    reg add $nxMain  /v DisableAllSounds /t REG_SZ /d 'True'  /f | Out-Null
    reg add $nxMain  /v HideTaskbar      /t REG_SZ /d 'False' /f | Out-Null
    Write-OK '已精确设置 Nexus：图标40、偏移32、放大68、关闭鼠标经过标签、禁用声音（状态栏保持显示）'
} else {
    Write-Warn '未找到 Nexus 安装包，尝试 winget 安装'
    winget install --id WinStep.Nexus --silent --accept-source-agreements --accept-package-agreements
}

# 5. 音频频谱条皮肤 (简约频谱) —— 从 .rmskin 解包，部署皮肤 + 插件
Write-Step '部署 Rainmeter 音频频谱条皮肤 (简约频谱)'
# 若 Rainmeter 正在运行，先关闭，避免插件 dll 被占用无法覆盖
Stop-Process -Name 'Rainmeter' -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500
if (-not (Test-Path $RainmeterSkinsDir)) { New-Item -ItemType Directory -Force -Path $RainmeterSkinsDir | Out-Null }

$rmskinPath = Join-Path $SkinsDir '简约频谱_0.16.3.rmskin'
$skinDest   = Join-Path $RainmeterSkinsDir $MusicSkin.ConfigName
if (Test-Path $rmskinPath) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $extract = Join-Path $TempDir 'rmskin_simplified'
    if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($rmskinPath, $extract)

    # 部署皮肤
    $skinSrc = Join-Path $extract ('Skins\' + $MusicSkin.ConfigName)
    if (Test-Path $skinDest) { Remove-Item $skinDest -Recurse -Force }
    Copy-Item $skinSrc $skinDest -Recurse -Force
    Write-OK "皮肤已部署到 $skinDest"

    # 部署插件（按 Rainmeter 架构选 64bit / 32bit）
    $rmDir = Split-Path $RainmeterExe -Parent
    if (-not (Test-Path $rmDir)) { $rmDir = Split-Path $RainmeterExe86 -Parent }
    $archDir = if ($rmDir -match 'Program Files \(x86\)') { '32bit' } else { '64bit' }
    $pluginSrc = Join-Path $extract ('Plugins\' + $archDir)
    $pluginDst = Join-Path $rmDir 'Plugins'
    if ((Test-Path $pluginSrc) -and (Test-Path $pluginDst)) {
        Copy-Item (Join-Path $pluginSrc '*.dll') $pluginDst -Force
        Write-OK "已部署频谱插件 ($archDir): PicInfo / Mouse / FileChoose"
    } else {
        Write-Warn "未找到插件目录 $pluginSrc，跳过"
    }
} else {
    Write-Warn "未找到 $rmskinPath，跳过部署"
}

# 部署 Coloration 时间套件（Time 时间 / Date 日期 / Day 星期）
$colRmskin = Join-Path $SkinsDir 'Coloration_1.01.rmskin'
if (Test-Path $colRmskin) {
    $colExtract = Join-Path $TempDir 'rmskin_coloration'
    if (Test-Path $colExtract) { Remove-Item $colExtract -Recurse -Force }
    [System.IO.Compression.ZipFile]::ExtractToDirectory($colRmskin, $colExtract)
    $colSrc = Join-Path $colExtract 'Skins\Coloration'
    $colDest = Join-Path $RainmeterSkinsDir 'Coloration'
    if (Test-Path $colDest) { Remove-Item $colDest -Recurse -Force }
    Copy-Item $colSrc $colDest -Recurse -Force
    Write-OK "时间套件 Coloration 已部署到 $colDest"
} else {
    Write-Warn "未找到 $colRmskin，跳过时间套件部署"
}

# 通过 Rainmeter.ini 激活皮肤（必须按 UTF-16LE 写，否则中文皮肤名会丢）
$rmIni = Join-Path $env:APPDATA 'Rainmeter\Rainmeter.ini'
if (Test-Path $rmIni) {
    $rb = [System.IO.File]::ReadAllBytes($rmIni)
    if ($rb.Length -ge 2 -and $rb[0] -eq 0xFF -and $rb[1] -eq 0xFE) {
        $rc = [System.Text.Encoding]::Unicode.GetString($rb)
    } else {
        $rc = [System.Text.Encoding]::UTF8.GetString($rb)
    }
} else {
    $rc = "[Rainmeter]`r`nSkinPath=$RainmeterSkinsDir`r`nLogging=0`r`n"
}
# 停用旧频谱皮肤
foreach ($oldSkin in @('AudioVisualizer','Lano Visualizer')) {
    $rc = [regex]::Replace($rc, ('(?m)(\[' + [regex]::Escape($oldSkin) + '\]\s*\r?\nActive=)1'), '${1}0')
}
# 需要激活的皮肤及位置（移除旧段后统一追加）
$activeSkins = @(
    @{ Name='简约频谱';        X=815;  Y=720 },
    @{ Name='Coloration\Time'; X=1025; Y=171 },
    @{ Name='Coloration\Date'; X=670;  Y=380 },
    @{ Name='Coloration\Day';  X=749;  Y=254 }
)
$skinNames = $activeSkins | ForEach-Object { $_.Name }
$rmOut = New-Object System.Collections.ArrayList
$skipSec = $false
foreach ($ln in ($rc -split "`r?`n")) {
    if ($ln -match '^\[(.+)\]$') {
        $skipSec = ($skinNames -contains $matches[1])
        if (-not $skipSec) { [void]$rmOut.Add($ln) }
        continue
    }
    if (-not $skipSec) { [void]$rmOut.Add($ln) }
}
foreach ($s in $activeSkins) {
    [void]$rmOut.Add('')
    [void]$rmOut.Add('[' + $s.Name + ']')
    [void]$rmOut.Add('Active=1')
    [void]$rmOut.Add('WindowX=' + $s.X)
    [void]$rmOut.Add('WindowY=' + $s.Y)
    [void]$rmOut.Add('ClickThrough=0')
    [void]$rmOut.Add('Draggable=1')
    [void]$rmOut.Add('SnapEdges=1')
    [void]$rmOut.Add('KeepOnScreen=1')
    [void]$rmOut.Add('AlwaysOnTop=0')
}
$rc = ($rmOut -join "`r`n")
[System.IO.File]::WriteAllText($rmIni, $rc, [System.Text.Encoding]::Unicode)
Write-OK '已在 Rainmeter.ini 中激活并定位 简约频谱 + Coloration 时间/日期/星期'

# 6. 开机自启
if ($EnableAutostart) {
    Write-Step '注册开机自启'
    $runKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
    if (Test-Path $RainmeterExe) {
        Set-ItemProperty -Path $runKey -Name 'Rainmeter' -Value "`"$RainmeterExe`"" -ErrorAction SilentlyContinue
        Write-OK 'Rainmeter 已加入自启'
    }
    $startupDir = [Environment]::GetFolderPath('Startup')
    $tbtLink = Join-Path $startupDir 'TranslucentTB.lnk'
    $app = Get-AppxPackage | Where-Object { $_.PackageFamilyName -eq $TranslucentTBPkg } | Select-Object -First 1
    if ($app) {
        $appId = (Get-AppxPackageManifest $app).Package.Applications.Application.Id | Select-Object -First 1
        if ($appId) {
            $ws = New-Object -ComObject WScript.Shell
            $lnk = $ws.CreateShortcut($tbtLink)
            $lnk.TargetPath = "$env:WINDIR\explorer.exe"
            $lnk.Arguments = "shell:AppsFolder\$TranslucentTBPkg!$appId"
            $lnk.Save()
            Write-OK 'TranslucentTB 已加入自启'
        }
    }
}

# 7. 启动程序（Nexus 必须以普通权限运行，否则会弹“较高权限”警告且无法使用）
Write-Step '启动程序'
Start-PackagedApp $TranslucentTBPkg
$nexusExe = $nexusExe86
if (-not (Test-Path $nexusExe)) { $nexusExe = $nexusExe64 }
if (Test-Path $nexusExe) {
    if (Get-Process -Name 'Nexus' -ErrorAction SilentlyContinue) {
        Write-OK 'Nexus 已在运行，跳过'
    } else {
        # 通过 explorer.exe 以普通权限启动；直接 Start-Process 会继承管理员权限，触发 Nexus 的 UAC 警告
        Start-Process 'explorer.exe' -ArgumentList ('"{0}"' -f $nexusExe)
        Start-Sleep -Seconds 2
        if (Get-Process -Name 'Nexus' -ErrorAction SilentlyContinue) {
            Write-OK '已启动 Nexus（普通权限）'
        } else {
            Write-Warn 'Nexus 未自动启动，请从开始菜单手动打开（普通权限）'
        }
    }
} else {
    Write-Warn '未找到 Nexus.exe，请手动启动'
}
# 以普通权限启动 Rainmeter（读取已写入的 Rainmeter.ini，自动加载 简约频谱）
$rmLaunch = $RainmeterExe
if (-not (Test-Path $rmLaunch)) { $rmLaunch = $RainmeterExe86 }
if (Test-Path $rmLaunch) {
    if (Get-Process -Name 'Rainmeter' -ErrorAction SilentlyContinue) {
        Write-OK 'Rainmeter 已在运行，跳过'
    } else {
        Start-Process 'explorer.exe' -ArgumentList ('"{0}"' -f $rmLaunch)
        Start-Sleep -Seconds 3
        if (Get-Process -Name 'Rainmeter' -ErrorAction SilentlyContinue) {
            Write-OK '已启动 Rainmeter（普通权限，已加载 简约频谱）'
        } else {
            Write-Warn 'Rainmeter 未自动启动，请手动打开 Rainmeter'
        }
    }
} else {
    Write-Warn '未找到 Rainmeter.exe'
}

# 8. 汇总
Write-Host ''
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host '   安装完成' -ForegroundColor Green
Write-Host '============================================================' -ForegroundColor Magenta
Write-Host '  - 任务栏已透明 (TranslucentTB, clear)'
Write-Host '  - 频谱条已加载 (简约频谱，随系统声音/QQ音乐 跳动)'
Write-Host '  - Nexus 配置已导入'
Write-Host '  - 壁纸、桌面/停靠栏图标请按视频手动设置'
Write-Host ''
