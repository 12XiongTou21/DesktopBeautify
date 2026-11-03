# DesktopBeautify · Windows 桌面美化一键自动化

> 一键还原抖音「保姆级桌面美化教程」的四件套效果：**任务栏透明 + 音频频谱 + Mac 风 Dock + 时间套件**。
> 纯 PowerShell 脚本，下载即用，离线/在线均可安装，可反复执行（幂等）。

![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell)
![License](https://img.shields.io/badge/License-MIT-green)

---

## ✨ 效果一览

| 模块 | 效果 | 实现 |
|---|---|---|
| 任务栏透明 | 任务栏完全透明 | TranslucentTB `accent=clear` |
| 音频频谱 | 21 条青蓝色频谱，随系统声音（QQ音乐等）跳动 | Rainmeter + 致美化「简约频谱」 |
| 时间套件 | 时间 / 日期 / 星期（白+金） | Rainmeter + 致美化「Coloration」 |
| Mac 风 Dock | 底部 Dock，图标 40、偏移 32、悬停放大 68、透明、无标签、静音 | Winstep Nexus |
| Dock 项目 | 仅保留 开始菜单 / 回收站 / Microsoft Edge | 注册表裁剪 |
| 布局 | 频谱居中在 Dock 上方 | Rainmeter.ini 定位 |

> 不含：动态壁纸（Wallpaper Engine）、桌面/停靠栏图标、桌面图标隐藏 —— 这些按视频手动即可。

---

## 🚀 快速开始

### 方式一：双击（推荐）

1. 克隆/下载本项目到本地，例如 `D:\DesktopBeautify`
2. 双击 **`run.bat`**（会自动请求管理员权限）
3. 等待脚本自动完成安装与配置

### 方式二：命令行

```powershell
# 管理员身份运行 PowerShell
Set-ExecutionPolicy -Scope Process Bypass -Force
.\install.ps1
```

> 首次运行会自动安装所有软件、部署皮肤、导入配置。**已安装的组件会自动跳过**，可安全重复运行。

### 安装前自检（可选）

```powershell
.\verify.ps1
```

会检查依赖文件、已装状态、配置合法性、网络连通性等，全部通过再安装更稳。

---

## 📁 项目结构

```
DesktopBeautify/
├── install.ps1                  # 一键安装（核心）
├── verify.ps1                   # 安装前可行性预检
├── set-nexus-params.ps1         # 精确写 Nexus 参数（绕过滑块步进）
├── diff-nexus.ps1               # Nexus 配置差异定位工具
├── run.bat                      # 双击入口（自动提权）
├── config/
│   └── TranslucentTB.settings.json   # 任务栏透明配置
├── Skins/
│   ├── nexus_config.reg              # Nexus 停靠栏配置（含裁剪后的 Dock 项目）
│   ├── nexus_config.baseline.reg     # Nexus 默认基线（diff 用）
│   ├── 简约频谱_0.16.3.rmskin          # 致美化「简约频谱」音频频谱皮肤包
│   └── Coloration_1.01.rmskin         # 致美化「Coloration」时间套件皮肤包
├── Software/                    # 软件安装包（已包含，可离线一键安装，约 100MB）
├── README.md
└── LICENSE
```

---

## 🧩 参数明细（与视频一致）

### Nexus Dock

| 参数 | 值 | 注册表键 |
|---|---|---|
| 位置 | 底部 | `DockOrientation1=3` |
| 偏移 | 32px | `DockEdgeOffset1=32` |
| 图标大小 | 40 | `DockIconSize1=40` |
| 悬停特效 | 放大 | `DockFxEffect1=1` |
| 放大后图标 | 68px | `DockMagPixels1=68` |
| 透明度 | 拉满（全透明） | `DockAlpha1=1` |
| 鼠标经过显示标签 | 关闭 | `DockShowLabels1=False` |
| 声音 | 禁用 | `DisableAllSounds=True` |
| 系统任务栏 | 保持显示 | `HideTaskbar=False` |

> Nexus 的滑块有步进，UI 里选不到 32/40/68 等精确值，所以脚本通过注册表**精确写死**。

### Rainmeter

| 皮肤 | 位置 |
|---|---|
| 简约频谱（音频频谱） | (815, 720)，Dock 上方居中 |
| Coloration\Time（时间） | (1025, 171) |
| Coloration\Date（日期） | (670, 380) |
| Coloration\Day（星期） | (749, 254) |

---

## 🔧 环境要求

- Windows 10 / 11（64 位优先）
- 管理员权限（脚本会自动提权）
- PowerShell 5.1+
- 若 `Software/` 目录为空，脚本会自动用 **winget** 安装所需软件（需联网）

---

## 🛠 工作原理

1. **TranslucentTB**：安装 MSIX 包（含 VC++/XAML 依赖），写入 `settings.json`（`accent=clear`）实现任务栏透明。
2. **Rainmeter**：静默安装 → 解包 `.rmskin` 部署皮肤 → 部署皮肤所需的 `PicInfo/Mouse/FileChoose` 插件 → 按 **UTF-16LE** 写 `Rainmeter.ini` 激活并定位皮肤（中文皮肤名必须用正确编码）。
3. **Nexus Dock**：静默安装 → 导入 `nexus_config.reg` → 用注册表精确覆盖滑块无法命中的参数。
4. **开机自启**：注册 Rainmeter 到 `HKCU\...\Run`，TranslucentTB 到启动文件夹，Nexus 通过自身配置自启。

---

## ❓ 常见问题

- **「禁止运行脚本」**：用 `run.bat` 双击（已带 `-ExecutionPolicy Bypass`），或先执行 `Set-ExecutionPolicy -Scope Process Bypass -Force`。
- **Nexus 安装报退出码 1**：脚本已兼容 Nexus 装在 `Program Files (x86)` 的情况；若仍失败，确认没有残留 Nexus 进程。
- **频谱不显示**：确认 Rainmeter 正在运行、`Rainmeter.ini` 里 `[简约频谱] Active=1`、插件 `PicInfo.dll` 已部署到 Rainmeter 的 `Plugins` 目录。
- **频谱不跳动**：它用 AudioLevel 监听系统默认输出设备，播放任意声音即跳动；若无效检查音量/默认播放设备。
- **任务栏未透明**：重启 TranslucentTB，或检查 `%LocalAppData%\Packages\28017CharlesMilette.TranslucentTB_...\RoamingState\settings.json`。
- **Nexus 弹出「较高权限」警告**：Nexus 必须以普通权限运行，脚本已用 `explorer.exe` 以普通权限启动；手动启动时请勿用管理员。

---

## 🙏 致谢

- [Rainmeter](https://www.rainmeter.net/)（GPL-2.0）
- [TranslucentTB](https://github.com/TranslucentTB/TranslucentTB)（GPL-3.0）
- [Winstep Nexus](https://www.winstep.net/nexus.asp)（个人免费，商用需授权）
- [致美化](https://zhutix.com/)：简约频谱（作者 朱门高悬云帆）、Coloration（作者 zhutix.com）

## 📄 许可

本仓库脚本采用 [MIT](LICENSE) 许可。第三方软件与皮肤遵循各自许可，请勿用于商业用途。
