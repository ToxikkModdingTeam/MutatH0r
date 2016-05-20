@echo off
cd /d "%~dp0"
setlocal
set error=0
del F:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Script\MutatH0r.u
if errorlevel 1 set error=1
del F:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Script\PredatH0r.u
if errorlevel 1 set error=1
del F:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\UDKMutatH0r.ini
if errorlevel 1 set error=1
del F:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\UDKPredatH0r.ini
if errorlevel 1 set error=1

rmdir /s /q F:\games\Steam\SteamApps\workshop\content\324810\603855831
mkdir F:\games\Steam\SteamApps\workshop\content\324810\603855831
del F:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Workshop\*MutatH0r* /s
del F:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Workshop\*PredatH0r* /s

if %error%==0 goto :eof
pause
:eof
