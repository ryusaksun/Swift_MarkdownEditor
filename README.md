# Swift Markdown Editor

一个基于 SwiftUI 和 Vditor 构建的现代化 iOS Markdown 编辑器。它结合了原生 iOS 的流畅体验和 Vditor 强大的 Web 编辑能力，专为移动端写作设计。

![Banner](Assets/banner.png) <!-- 你可以后续添加一个 banner -->

## ✨ 主要特性

- **强大内核**：集成 [Vditor](https://github.com/vditor/vditor) 编辑器，支持所见即所得 (WYSIWYG)、即时渲染 (IR) 和分屏预览 (SV) 模式。
- **GitHub 图床集成**：
  - 支持多图选择批量上传。
  - 支持直接调用相机拍照上传。
  - 图片自动上传至配置的 GitHub 仓库，并自动插入 Markdown 链接。
- **现代化 UI 设计**：
  - 采用 SwiftUI 构建，拥有流畅的动画和过渡效果。
  - **沉浸式暗色模式**：专为夜间写作优化。
  - **OLED 纯黑模式**：极致省电，黑色背景更深邃。
  - **Glassmorphism 风格**：精美的上传 HUD 和 UI 元素。
- **触觉反馈**：操作时的细腻震动反馈，提升交互质感。

## 🛠️ 技术栈

- **SwiftUI**：构建声明式用户界面。
- **WebKit (WKWebView)**：通过 Bridge 桥接 Vditor Web 编辑器。
- **GitHub API**：使用 REST API 实现图片上传功能。
- **PhotosUI**：原生照片选择器集成。

## 🚀 快速开始

### 前置要求

- Xcode 15.0+
- iOS 17.0+
- 一个 GitHub 账号（用于图床功能）

### 安装步骤

1. **克隆仓库**

   ```bash
   git clone git@github.com:SUNSIR007/Swift_MarkdownEditor.git
   cd Swift_MarkdownEditor
   ```

2. **配置 GitHub Token**

   为了使用图片上传功能，你需要配置 GitHub Personal Access Token (PAT)。

   - 打开 `Swift_MarkdownEditor/Models/LocalConfig.swift` 文件。
   - 找到 `myGitHubToken` 变量。
   - 填入你的 GitHub PAT（确保拥有 `repo` 权限以读写仓库）。
   
   > **⚠️ 注意**：`LocalConfig.swift` 包含敏感信息，请确保不要将其误提交到公共仓库（项目已将其加入 `.gitignore`，但请二次确认）。

3. **运行项目**

   - 双击打开 `Swift_MarkdownEditor.xcodeproj`。
   - 选择你的模拟器或真机。
   - 点击 Run (Cmd + R)。

## 📝 使用说明

1. **编辑文本**：直接在编辑器区域输入 Markdown 文本。
2. **插入图片**：
   - 点击顶部栏的 **图片图标** 从相册选择（支持多选）。
   - 点击 **相机图标** 直接拍照。
   - 图片会自动上传，上传中会显示幽灵动画 HUD，完成后自动插入编辑器。
3. **切换主题**：点击顶部栏的 **设置/主题图标** 可以在标准暗色和 OLED 模式间切换。

## 📂 项目结构

```
Swift_MarkdownEditor/
├── Models/          # 数据模型 (AppConfig, LocalConfig 等)
├── Views/           # SwiftUI 视图 (ContentView, EditorView 等)
├── ViewModels/      # 业务逻辑 (EditorViewModel)
├── Services/        # 服务层 (GitHubService, ImageService)
├── Resources/       # 资源文件 (Vditor 静态资源)
└── Theme/           # 主题管理
```

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests 来改进这个项目！

## 📄 许可证

[MIT License](LICENSE) (如有)
