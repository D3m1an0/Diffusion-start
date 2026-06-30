@echo off
:: Diffusion-Start — Запуск установщика для Windows
:: Требует права администратора (для создания симлинков)

net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Запрашиваю права администратора...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Снимаем ограничение на выполнение PS-скриптов и запускаем
powershell -ExecutionPolicy Bypass -File "%~dp0install-windows.ps1"
pause
