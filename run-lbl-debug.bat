@echo off

set "MOD_NAME=Piraeus.BetterHistoryMod"
set "LBL_PATH=D:\steam\steamapps\common\Luck be a Landlord"
set "MODS_PATH=%LBL_PATH%\GDWeave\mods"
set "MOD_DEST_PATH=%MODS_PATH%\%MOD_NAME%"

set "BUILD_SOURCE_PATH=.\Piraeus.BetterHistoryMod\bin\Debug\net8.0"

echo "Copying mod files..."
if not exist "%MOD_DEST_PATH%" (
    mkdir "%MOD_DEST_PATH%"
)
copy /Y "%BUILD_SOURCE_PATH%\%MOD_NAME%.dll" "%MOD_DEST_PATH%\"
copy /Y ".\Piraeus.BetterHistoryMod\manifest.json" "%MOD_DEST_PATH%\manifest.json"

echo "Starting game..."
@REM set GDWEAVE_DEBUG=1
set GDWEAVE_CONSOLE=1
set GDWEAVE_NO_CACHE=1
set GDWEAVE_DUMP_SOURCE=1
set GDWEAVE_DUMP_PATCHED=1
"%LBL_PATH%\Luck be a Landlord.exe" --verbose
