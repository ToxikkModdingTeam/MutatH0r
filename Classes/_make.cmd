@echo off
cd /d "%~dp0"
set cwd=%cd%

if "%1"=="compress" goto compress

:build
copy MutatH0r_Content.upk ..\..\..\..\UDKGame\Content >nul
if errorlevel 1 goto error
F:\games\Steam\SteamApps\common\TOXIKK\Binaries\Win32\TOXIKK.exe make -configsubdir=LocalBuild
if errorlevel 1 goto error
goto :eof

:compress
cd ..\..\..\..\UDKGame\Script_LocalBuild
if errorlevel 1 goto error
F:\games\Steam\SteamApps\common\TOXIKK\Binaries\Win32\TOXIKK.exe stripsource MutatH0r.u -configsubdir=LocalBuild
if errorlevel 1 goto error
goto :eof

:error
pause

:eof