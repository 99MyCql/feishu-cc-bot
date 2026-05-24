<#
  飞书 CC Bot - Windows 一键安装脚本
  自动安装: Node.js / Git / Claude Code CLI / lark-cli / playwright-cli / lark-channel-bridge / AI Skills

  用法:
    # 方式 1 — 一行命令安装（推荐）:
    powershell -c "iex (iwr -Uri 'https://raw.githubusercontent.com/99MyCql/feishu-cc-bot/main/install.ps1')"

    # 方式 2 — 下载后双击 install.bat
    # 方式 3 — 下载后右键 install.ps1 → 使用 PowerShell 运行
#>

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"

# 修复 PowerShell 中文乱码问题
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 >$null

# ============================================================
# 自动提权：如果未以管理员身份运行，自动申请管理员权限
# ============================================================
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`n请求管理员权限..." -ForegroundColor Yellow
    $url = "https://raw.githubusercontent.com/99MyCql/feishu-cc-bot/main/install.ps1"
    $tmpPath = Join-Path $env:TEMP "feishu-cc-bot-install.ps1"
    try {
        Invoke-WebRequest -Uri $url -OutFile $tmpPath -UseBasicParsing
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tmpPath`"" -Wait
    } catch {
        Write-Host "自动提权失败，请以管理员身份运行：" -ForegroundColor Red
        Write-Host "  1. 右键点击 install.bat" -ForegroundColor White
        Write-Host "  2. 选择"以管理员身份运行"" -ForegroundColor White
    }
    exit
}

# ============================================================
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path $env:TEMP "feishu-cc-bot-install-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-Step {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "`n[$timestamp] --- $Message"
    Write-Host $line -ForegroundColor Cyan
    Add-Content -Path $LogFile -Value $line
}

function Write-Info {
    param([string]$Message)
    $timestamp = Get-Date -Format "HH:mm:ss"
    $line = "  $Message"
    Write-Host $line -ForegroundColor Gray
    Add-Content -Path $LogFile -Value "  $Message"
}

function Write-Success {
    param([string]$Message)
    $line = "  ✓ $Message"
    Write-Host $line -ForegroundColor Green
    Add-Content -Path $LogFile -Value "  ✓ $Message"
}

function Write-Warn {
    param([string]$Message)
    $line = "  ! $Message"
    Write-Host $line -ForegroundColor Yellow
    Add-Content -Path $LogFile -Value "  ! $Message"
}

function Write-Error {
    param([string]$Message)
    $line = "  ✗ $Message"
    Write-Host $line -ForegroundColor Red
    Add-Content -Path $LogFile -Value "  ✗ $Message"
}

function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

function Test-CommandInstalled {
    param([string]$Command)
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Stop"
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    } finally {
        $ErrorActionPreference = $oldPreference
    }
}

# ============================================================
Write-Host @"

============================================
  飞书 CC Bot - 一键安装
  把你的电脑变成飞书 AI 助手
  全程自动安装，请勿关闭窗口
============================================

"@ -ForegroundColor Magenta

$startTime = Get-Date
Add-Content -Path $LogFile -Value "=== 安装开始: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

# ============================================================
# 步骤 1: 检查系统环境
# ============================================================
Write-Step "[1/6] 检查系统环境..."

$osInfo = Get-CimInstance -ClassName Win32_OperatingSystem
$osVersion = [version]$osInfo.Version
if ($osVersion.Major -lt 10) {
    Write-Error "仅支持 Windows 10 及以上系统"
    Read-Host "按回车退出"
    exit 1
}
Write-Info "操作系统: $($osInfo.Caption) $($osInfo.Version)"

if (-not [Environment]::Is64BitOperatingSystem) {
    Write-Error "仅支持 64 位系统"
    Read-Host "按回车退出"
    exit 1
}
Write-Info "系统类型: 64 位"

$drive = Get-PSDrive -Name "C" -ErrorAction SilentlyContinue
if ($drive -and $drive.Free -lt 2GB) {
    Write-Warn "C 盘剩余空间不足 2GB，安装可能失败"
} else {
    Write-Info "磁盘空间: 充足"
}

# ============================================================
# 步骤 2: 安装 Node.js
# ============================================================
Write-Step "[2/6] 安装 Node.js..."

$nodeInstalled = $false
try {
    $nodeVer = node --version 2>$null
    $npmVer = npm --version 2>$null
    if ($nodeVer -and $npmVer) {
        $versionNum = [version]($nodeVer -replace 'v','')
        if ($versionNum -ge [version]"20.0.0") {
            Write-Success "Node.js 已安装: $nodeVer, npm $npmVer"
            $nodeInstalled = $true
        } else {
            Write-Warn "Node.js 版本过低 ($nodeVer)，需要 >= 20，将升级"
        }
    }
} catch {
    Write-Info "Node.js 未安装，准备安装"
}

if (-not $nodeInstalled) {
    $wingetAvailable = try { winget --version 2>$null; $true } catch { $false }

    if ($wingetAvailable) {
        Write-Info "通过 winget 安装 Node.js LTS..."
        winget install OpenJS.NodeJS.LTS --accept-source-agreements --silent 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) { $nodeInstalled = $true }
    }

    if (-not $nodeInstalled) {
        Write-Info "通过官方安装包安装 Node.js LTS..."
        $msiPath = Join-Path $env:TEMP "node-lts.msi"
        try {
            Invoke-WebRequest -Uri "https://nodejs.org/dist/v22.14.0/node-v22.14.0-x64.msi" -OutFile $msiPath -UseBasicParsing
            Start-Process msiexec.exe -Wait -ArgumentList "/i `"$msiPath`" /quiet /norestart"
            Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
            $nodeInstalled = $true
        } catch {
            Write-Error "Node.js 安装失败: $_"
            Write-Warn "请手动下载安装: https://nodejs.org (选择 LTS 版本)"
        }
    }

    if ($nodeInstalled) {
        Refresh-Path
        $ver = node --version 2>$null
        Write-Success "Node.js 安装完成: $ver"
    }
}

if (-not $nodeInstalled) {
    Write-Host "`nNode.js 安装失败，无法继续。请手动安装后重试：https://nodejs.org" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}

Refresh-Path

# ============================================================
# 步骤 3: 安装 Git
# ============================================================
if (Test-CommandInstalled "git") {
    Write-Step "[3/6] 检查 Git..."
    Write-Success "Git 已安装: $(git --version)"
} else {
    Write-Step "[3/6] 安装 Git..."
    $wingetAvailable = try { winget --version 2>$null; $true } catch { $false }
    if ($wingetAvailable) {
        Write-Info "通过 winget 安装 Git..."
        winget install Git.Git --accept-source-agreements --silent 2>&1 | Out-Null
    }
    if (Test-CommandInstalled "git") {
        Write-Success "Git 安装完成: $(git --version)"
    } else {
        Write-Warn "Git 未自动安装，不影响核心功能，可跳过"
    }
}

# ============================================================
# 步骤 4-6: 安装 npm 全局包
# ============================================================
function Install-GlobalPackage {
    param([string]$PackageName, [string]$DisplayName)

    $installed = npm list -g --depth=0 2>$null | Select-String "^.+ $PackageName@" -SimpleMatch
    if ($installed) {
        $ver = ($installed -split '@')[-1]
        Write-Success "$DisplayName 已安装: v$ver"
        return $true
    }

    Write-Info "正在安装 $DisplayName ..."
    npm install -g $PackageName 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Success "$DisplayName 安装完成"
        return $true
    } else {
        Write-Error "$DisplayName 安装失败"
        return $false
    }
}

Write-Step "[4/6] 安装 Claude Code CLI..."
npm cache clean --force 2>$null | Out-Null
$claudeOk = Install-GlobalPackage -PackageName "@anthropic-ai/claude-code" -DisplayName "Claude Code CLI"
if (-not $claudeOk) {
    Write-Host "`nClaude Code CLI 安装失败，无法继续。" -ForegroundColor Red
    Read-Host "按回车退出"
    exit 1
}

Refresh-Path

# ============================================================
# 步骤 5: 推荐手动安装的工具
# ============================================================
Write-Step "[5/6] 推荐工具（建议手动安装）..."

Write-Host @"

飞书机器人（二选一即可）：

  lark-channel-bridge（飞书 ↔ Claude Code 桥接）
    官网: https://github.com/zarazhangrui/feishu-claude-code-bridge
    安装: npm install -g lark-channel-bridge
    启动: lark-channel-bridge run

  metabot（通用 bot 框架）
    官网: https://github.com/xvirobotics/metabot
    安装: irm https://raw.githubusercontent.com/xvirobotics/metabot/main/install.ps1 | iex

其他推荐工具：

  lark-cli（飞书 CLI）
    官网: https://www.feishu.cn/feishu-cli
    安装: npx @larksuite/cli@latest install

  playwright-cli（浏览器操作）
    安装: npm install -g @playwright/cli
    浏览器: playwright install chromium

  飞书 AI Skills（日历/文档/表格/妙记等）
    安装: npx @larksuite/cli skills install

  cc-switch（模型切换）
    官网: https://github.com/farion1231/cc-switch
    安装: npm install -g cc-switch

"@ -ForegroundColor White

# ============================================================
# 完成
# ============================================================
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalMinutes.ToString("F1")

Write-Step "[6/6] 安装完成！"
Write-Host @"

============================================
  所有核心组件安装成功！（耗时: ${duration}分钟）
  安装日志已保存至: $LogFile
============================================

"@ -ForegroundColor Green

Write-Host "接下来需要做的事：" -ForegroundColor Yellow
Write-Host ""
Write-Host "  1. 登录 Claude Code：" -ForegroundColor Cyan
Write-Host "     claude login" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "  2. 安装飞书机器人（见上方推荐），启动后扫码绑定" -ForegroundColor Cyan
Write-Host ""
Write-Host "============================================" -ForegroundColor Magenta
Write-Host "  如遇问题，查看安装日志："
Write-Host "  $LogFile"
Write-Host "============================================" -ForegroundColor Magenta

Add-Content -Path $LogFile -Value "=== 安装结束: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="

if ($host.Name -like "*ConsoleHost*") {
    Write-Host "`n按回车键退出..."
    Read-Host > $null
}
