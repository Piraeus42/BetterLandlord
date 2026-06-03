@echo off
setlocal

REM ================================================
REM  GDWeave Mod Build Script - HelloWorldMod
REM  将 GAME_DIR 修改为你的游戏安装目录
REM ================================================

set GAME_DIR=D:\steam\steamapps\common\Luck be a Landlord
set MOD_ID=HelloWorldMod

set GDWEAVE_CORE=%GAME_DIR%\GDWeave\core

echo.
echo Building %MOD_ID%...
dotnet build "%~dp0..\HelloWorldMod" -c Release
if %ERRORLEVEL% NEQ 0 (
    echo BUILD FAILED
    pause
    exit /b %ERRORLEVEL%
)

echo.
echo Deploying to game mods folder...
set MOD_DIR=%GAME_DIR%\GDWeave\mods\%MOD_ID%
if not exist "%MOD_DIR%" mkdir "%MOD_DIR%"
copy /Y "%~dp0..\HelloWorldMod\bin\Release\net8.0\*.dll" "%MOD_DIR%\" >nul
copy /Y "%~dp0..\HelloWorldMod\manifest.json"          "%MOD_DIR%\" >nul

echo Done -- %MOD_DIR%
echo.
echo Run the game to test.
