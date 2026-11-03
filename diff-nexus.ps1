# =============================================================================
#  desktop-beautify / diff-nexus.ps1
#  对比两个 Nexus 配置导出文件，列出变化的注册表键
#  用途：重新导出 Nexus 配置后，自动找出「偏移/透明度/跳动」等参数对应的键
# -----------------------------------------------------------------------------
#  用法：
#    1) 先保存一份基线（默认配置）为 Skins\nexus_config.baseline.reg
#    2) 在 Nexus 里改好设置，导出到 Skins\nexus_config.reg
#    3) 运行本脚本：.\diff-nexus.ps1
#  它会打印所有变化了的键及旧/新值。
# =============================================================================

param(
    [string]$Baseline = (Join-Path $PSScriptRoot 'Skins\nexus_config.baseline.reg'),
    [string]$Current  = (Join-Path $PSScriptRoot 'Skins\nexus_config.reg')
)

# 读取 .reg（UTF-16 LE）为 "节\键名" = 值 的映射
function Read-Reg([string]$path) {
    $text = [System.Text.Encoding]::Unicode.GetString([System.IO.File]::ReadAllBytes($path))
    $map = @{}
    $section = ''
    foreach ($line in ($text -split "`r?`n")) {
        $line = $line.Trim()
        if ($line -match '^\[(.+)\]$') { $section = $matches[1]; continue }
        if ($line -match '^"([^"]+)"="(.*)"$') {
            $map["$section\$($matches[1])"] = $matches[2]
        } elseif ($line -match '^"([^"]+)"=(.+)$') {
            $map["$section\$($matches[1])"] = $matches[2].Trim()
        }
    }
    return $map
}

if (-not (Test-Path $Baseline)) { Write-Host "缺少基线文件: $Baseline" -ForegroundColor Red; exit 1 }
if (-not (Test-Path $Current))  { Write-Host "缺少当前配置: $Current" -ForegroundColor Red; exit 1 }

$b = Read-Reg $Baseline
$c = Read-Reg $Current
$allKeys = @($b.Keys + $c.Keys) | Sort-Object -Unique

Write-Host '=== Nexus 配置差异 ===' -ForegroundColor Cyan
$changed = 0
foreach ($k in $allKeys) {
    $ov = if ($b.ContainsKey($k)) { $b[$k] } else { '<无>' }
    $nv = if ($c.ContainsKey($k)) { $c[$k] } else { '<无>' }
    if ($ov -ne $nv) {
        Write-Host ("[变化] {0}" -f $k) -ForegroundColor Yellow
        Write-Host ("       旧: {0}" -f $ov)
        Write-Host ("       新: {0}" -f $nv)
        $changed++
    }
}
Write-Host ''
Write-Host ("共 {0} 个键发生变化" -f $changed) -ForegroundColor Cyan
