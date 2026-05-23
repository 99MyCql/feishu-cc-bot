@echo off
chcp 65001 >nul
title 飞书 CC Bot 一键安装工具
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
