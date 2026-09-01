# RegisterBitEditor Handoff

## 项目概览

RegisterBitEditor 是一个原生 macOS SwiftUI 寄存器位编辑器。目前只构建 Apple Silicon（arm64），最低支持 macOS 13。

- 项目根目录：克隆后的 `registerdump` 仓库目录
- Xcode 工程：`RegisterBitEditor.xcodeproj`
- App target：`RegisterBitEditor`
- Bundle ID：`com.codex.RegisterBitEditor`
- 当前版本：`0.1 (14)`
- Release App：由 Release 构建生成，不纳入 Git
- 分发压缩包：作为 GitHub Release 附件发布，不纳入 Git

## 当前产品要求

- 默认 32 位，底部最右侧“64位模式”按钮切换位宽。
- 32 位窗口为 560×350；64 位自动平滑扩大到 680×470，切回时自动缩小。
- 16 bit 一行；4 bit 为一个小组，两个小组组成一个 8-bit 大组。
- bit 编号位于按钮框外，按钮框中只显示 0/1。
- Hex、Dec、Bin 标签及输入框左边缘对齐。
- Hex 显示 `0x` 前缀，但不补前导零；Bin、Oct 同样不补零、不显示前缀。
- Hex / Dec / Oct / Bin 实时同步并支持直接编辑。
- 支持 32/64 位有符号十进制显示。
- 默认窗口置顶。
- 底部按钮：清除、ASCII、计算器、左移、移位数、右移、64位模式。
- ASCII 弹窗四栏显示完整 0–127 码表，无滚动条，并显示当前寄存器字节解释。
- “计算器”打开 `/System/Applications/Calculator.app`，旧系统路径作为回退。
- AND / OR / XOR / NOT 位运算在菜单栏“位运算”中；前三项弹窗输入操作数。
- 每个进制标签可点击复制对应数值；菜单中也可复制 Hex。

## 源码结构

- `RegisterBitEditor/RegisterBitEditorApp.swift`
  - App 入口、默认窗口尺寸、菜单命令。
- `RegisterBitEditor/ContentView.swift`
  - 主界面、bit 分组、数值输入、底部按钮、32/64 位动态布局尺寸。
- `RegisterBitEditor/RegisterViewModel.swift`
  - UI 状态、格式同步、剪贴板、置顶、计算器、ASCII 码表、位运算弹窗。
- `RegisterBitEditor/RegisterCore.swift`
  - 无 UI 的解析、格式化、掩码、移位和位运算逻辑。
- `RegisterBitEditor/WindowLevelController.swift`
  - 获取 NSWindow、控制 `.floating` 置顶层级、按位宽平滑调整窗口大小。
- `RegisterBitEditor/Assets.xcassets/AppIcon.appiconset/`
  - macOS AppIcon 的 16–1024 像素资源。
- `Tests/CoreSelfTest.swift`
  - 核心数值逻辑自测文件，不属于 Xcode target。

## 图标信息

图标主图是 `RegisterBitEditor/Design/AppIcon-1024.png`。视觉为扁平蓝色方圆形底板、白色芯片轮廓与青色/深蓝色 4×2 bit 方块，没有金属、玻璃、复杂阴影或拟物细节。`Assets.xcassets/AppIcon.appiconset/` 中的各尺寸 PNG 由这张 1024 主图缩放生成。

原始生成提示词摘要：简单、人工设计感的扁平 macOS 工具图标；居中的白色芯片轮廓和 4×2 bit 阵列；仅使用蓝、青、白三类颜色；无文字、无商标、无金属、无玻璃、无发光、无 3D，透明外缘且缩小后清晰。使用 Codex 内置 ImageGen 生成并进行透明背景提取。

## 构建方法

系统当前 `xcode-select` 可能仍指向 Command Line Tools，因此命令行构建应显式指定完整 Xcode：

```sh
cd registerdump
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  /Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project RegisterBitEditor.xcodeproj \
  -scheme RegisterBitEditor \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath /private/tmp/RegisterBitEditorDerivedData \
  CODE_SIGNING_ALLOWED=NO build
```

成功后，从以下位置取得构建产物：

```text
/private/tmp/RegisterBitEditorDerivedData/Build/Products/Release/RegisterBitEditor.app
```

交付时应在临时输出目录创建全新的 App，进行临时签名，并将压缩包上传为 GitHub Release 附件。不要把 `.app` 或 `.zip` 提交进源码仓库：

```sh
mkdir -p /private/tmp/RegisterBitEditorRelease
ditto /private/tmp/RegisterBitEditorDerivedData/Build/Products/Release/RegisterBitEditor.app /private/tmp/RegisterBitEditorRelease/RegisterBitEditor.app
strip -Sx /private/tmp/RegisterBitEditorRelease/RegisterBitEditor.app/Contents/MacOS/RegisterBitEditor
codesign --force --deep --sign - /private/tmp/RegisterBitEditorRelease/RegisterBitEditor.app
codesign --verify --deep --strict /private/tmp/RegisterBitEditorRelease/RegisterBitEditor.app
ditto -c -k --sequesterRsrc --keepParent /private/tmp/RegisterBitEditorRelease/RegisterBitEditor.app /private/tmp/RegisterBitEditor-macOS.zip
```

修改后务必同步增加 `MARKETING_VERSION` 和 `CURRENT_PROJECT_VERSION`，然后完成 Release 编译，不要只交付源码。

## 验证清单

1. 完全退出旧 App（⌘Q），再启动新 App，避免 macOS 激活旧进程。
2. 检查 Finder 和 Dock 是否显示新的芯片图标。
3. 确认默认 32 位、默认置顶，窗口为紧凑尺寸。
4. 点击 bit，确认四种进制实时同步且不补前导零。
5. 切换 64 位，确认窗口自动放大并显示 bit63…bit0；切回自动缩小。
6. 检查 Hex、Dec、Bin 左边缘对齐。
7. 检查有符号、大写、清除、复制、左右移位。
8. 点击 ASCII，确认 0–127 一页显示且没有滚动条。
9. 点击计算器，确认系统 Calculator.app 打开。
10. 检查置顶关闭和重新开启均立即生效。
11. 运行 `codesign --verify --deep --strict /private/tmp/RegisterBitEditorRelease/RegisterBitEditor.app`。
12. 用 `stat` 核对 Release App 和 ZIP 的时间戳确实为本次构建时间。

## 分发注意事项

当前输出使用 ad-hoc 临时签名，没有 Developer ID 公证。发送给其他用户后，对方首次打开可能需要右键选择“打开”。正式公开分发时应改用 Developer ID Application 证书签名并进行 Apple notarization。
