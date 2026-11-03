# =============================================================================
#  desktop-beautify / set-nexus-params.ps1
#  直接写注册表设置 Nexus 精确参数（绕过滑块步进，精确到 32/40 等）
# -----------------------------------------------------------------------------
#  背景：Nexus 设置界面里的滑块有步进，拖动会跳值（如 31->33 跳过 32），
#        无法在 UI 里精确命中视频参数。注册表存的是整数，可精确写入。
#  用法：管理员 PowerShell 运行  .\set-nexus-params.ps1
# =============================================================================

$ErrorActionPreference = 'Stop'

$keyMain  = 'HKCU\Software\WinSTEP2000\NeXuS'
$keyDocks = 'HKCU\Software\WinSTEP2000\NeXuS\Docks'

# -----------------------------------------------------------------------------
#  已确认参数（可直接精确写入）
# -----------------------------------------------------------------------------
$confirmed = @(
    @{ Key = $keyMain;  Name = 'DockIconSize1';    Value = '40' },    # 外观-图标大小 40
    @{ Key = $keyDocks; Name = 'DockIconSize1';    Value = '40' },
    @{ Key = $keyDocks; Name = 'DockEdgeOffset1';  Value = '32' },    # 位置-底部偏移 32px
    @{ Key = $keyDocks; Name = 'DockMagPixels1';   Value = '68' },    # 鼠标悬停-放大后图标 68px
    @{ Key = $keyMain;  Name = 'DockShowLabels1';  Value = 'False' }, # 关闭“鼠标经过显示图标标签”
    @{ Key = $keyDocks; Name = 'DockShowLabels1';  Value = 'False' },
    @{ Key = $keyMain;  Name = 'DisableAllSounds'; Value = 'True' }   # 禁用声音
)

# -----------------------------------------------------------------------------
#  待确认参数（需先按视频在 Nexus 里拖到最接近值 → 重新导出配置 → 由脚本作者
#  做 diff 精确定位键名后，再填入下方并取消注释。届时可精确写入 32/100 等）
# -----------------------------------------------------------------------------
# $pending = @(
#     @{ Key = $keyDocks; Name = 'DockIconAlpha1'; Value = '100' },  # Dock 透明度 100（全透明）——待确认键
#     @{ Key = $keyDocks; Name = 'DockFxEffect1';  Value = '2'   },  # 特效=跳动(bounce)——待确认枚举值
#     @{ Key = $keyDocks; Name = 'DockPosY1';      Value = '?'   }   # 位置-底部偏移 32px——待确认键/坐标
# )

# -----------------------------------------------------------------------------
Write-Host '==> 关闭 Nexus 以免退出时覆盖修改' -ForegroundColor Cyan
Stop-Process -Name 'Nexus' -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host '==> 写入精确参数' -ForegroundColor Cyan
foreach ($p in $confirmed) {
    reg add $p.Key /v $p.Name /t REG_SZ /d $p.Value /f | Out-Null
    Write-Host ("  [OK] {0}\{1} = {2}" -f $p.Key, $p.Name, $p.Value) -ForegroundColor Green
}

Write-Host '==> 重启 Nexus' -ForegroundColor Cyan
$nexus = Join-Path ${env:ProgramFiles(x86)} 'Winstep\Nexus.exe'
if (-not (Test-Path $nexus)) { $nexus = Join-Path ${env:ProgramFiles} 'Winstep\Nexus.exe' }
if (Test-Path $nexus) {
    Start-Process $nexus
    Write-Host '  [OK] 已重启 Nexus' -ForegroundColor Green
} else {
    Write-Host '  [!!] 未找到 Nexus.exe，请手动启动' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '完成。透明度/特效/偏移 三个参数待重新导出配置后精确定位键名，再写入。' -ForegroundColor Cyan
Write-Host '下一步：在 Nexus 里把这三个拖到最接近值，然后执行：' -ForegroundColor Cyan
Write-Host '  reg export "HKCU\Software\WinSTEP2000\NeXuS" "D:\DesktopBeautify\Skins\nexus_config.reg" /y' -ForegroundColor White
