# 飞书 CC Bot

在飞书里跟 Claude 聊天，自动帮你装好所有工具。

## 一键安装

打开 PowerShell 或命令提示符（cmd），粘贴以下命令运行：

### 方式一：一行命令（推荐）

```powershell
powershell -c "iex (iwr -Uri 'https://raw.githubusercontent.com/99MyCql/feishu-cc-bot/main/install.ps1')"
```

> 系统会弹出管理员权限请求窗口，点击"是"即可。

### 方式二：下载后双击运行

1. 下载 [install.bat](https://raw.githubusercontent.com/99MyCql/feishu-cc-bot/main/install.bat)
2. 右键 → **以管理员身份运行**

---

## 安装后操作

### 1. 登录 Claude Code

```bash
claude login
```

浏览器会自动打开，用 Anthropic 账号登录。

### 2. 启动飞书机器人

```bash
lark-channel-bridge run
```

首次运行会显示二维码，用手机飞书 App 扫码绑定即可开始对话。

---

## 自动安装内容

| 组件 | 作用 |
|------|------|
| Node.js | 运行环境 |
| Git | 版本管理 |
| Claude Code CLI | AI 对话引擎 |
| lark-channel-bridge | 飞书 ↔ Claude 桥接 |
| lark-cli | 飞书 API 命令行 |
| playwright-cli | 浏览器操作 |
| Feishu AI Skills | 飞书日历/文档/表格等 AI 技能 |

## 系统要求

- Windows 10 / 11（64 位）
- 网络连接
- 管理员权限
