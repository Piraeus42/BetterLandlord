@echo off
setlocal
echo === BetterHistoryMod Alpha Package Builder ===

set GAME_DIR=D:\steam\steamapps\common\Luck be a Landlord
set DIST_DIR=%~dp0..\dist\BetterHistoryMod
set ZIP_NAME=BetterHistoryMod-alpha.zip

if not exist "%GAME_DIR%\Luck be a Landlord.exe" (
    echo [ERROR] Game not found at %GAME_DIR%
    pause
    exit /b 1
)

echo [1/4] Building Release...
dotnet build "%~dp0..\Piraeus.BetterHistoryMod.sln" -c Release
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Build failed
    pause
    exit /b 1
)

echo [2/4] Creating dist folder...
if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
mkdir "%DIST_DIR%"
mkdir "%DIST_DIR%\GDWeave\core"
mkdir "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod"
mkdir "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\Assets\Icons"

echo [3/4] Copying files...
:: GDWeave loader
xcopy /Y "%GAME_DIR%\winmm.dll" "%DIST_DIR%\"

:: GDWeave core
xcopy /Y "%GAME_DIR%\GDWeave\core\GDWeave.dll" "%DIST_DIR%\GDWeave\core\"
xcopy /Y "%GAME_DIR%\GDWeave\core\Serilog.dll" "%DIST_DIR%\GDWeave\core\"

:: Mod
xcopy /Y "%~dp0..\Piraeus.BetterHistoryMod\bin\Release\net8.0\Piraeus.BetterHistoryMod.dll" "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\"
xcopy /Y "%~dp0..\Piraeus.BetterHistoryMod\manifest.json" "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\"

:: UI
xcopy /Y "%~dp0..\Piraeus.BetterHistory.UI\bin\Release\net8.0-windows\Piraeus.BetterHistory.UI.exe" "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\"
xcopy /Y "%~dp0..\Piraeus.BetterHistory.UI\bin\Release\net8.0-windows\Piraeus.BetterHistory.UI.dll" "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\"
xcopy /Y "%~dp0..\Piraeus.BetterHistory.UI\bin\Release\net8.0-windows\Piraeus.BetterHistory.UI.runtimeconfig.json" "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\"

:: Icons
xcopy /Y /I "E:\code\LBaL\icons\*.png" "%DIST_DIR%\GDWeave\mods\Piraeus.BetterHistoryMod\Assets\Icons\"

:: README
xcopy /Y "%~dp0..\docs\release-readme.txt" "%DIST_DIR%\README.txt"

echo [4/4] Creating zip...
powershell -Command "Compress-Archive -Path '%DIST_DIR%\*' -DestinationPath '%DIST_DIR%\..\%ZIP_NAME%' -Force"

echo.
echo === Done ===
echo Package: dist\%ZIP_NAME%
echo.
echo Install: extract to game root, overwrite all
pause
