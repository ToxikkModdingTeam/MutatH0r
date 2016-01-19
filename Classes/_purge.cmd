@echo off
cd /d %~dp0
setlocal
set error=0
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Content\MutatH0r.u
if errorlevel 1 set error=1
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Content\PredatH0r.u
if errorlevel 1 set error=1
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\UDKMutatH0r.ini
if errorlevel 1 set error=1
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\UDKPredatH0r.ini
if errorlevel 1 set error=1
if %error%==0 goto :eof
pause
:eof
