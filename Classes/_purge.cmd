@echo off
cd /d %~dp0
setlocal
set error=0
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Script\MutatH0r.u
if errorlevel 1 set error=1
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Script\PredatH0r.u
if errorlevel 1 set error=1
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\UDKMutatH0r.ini
if errorlevel 1 set error=1
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\UDKPredatH0r.ini
if errorlevel 1 set error=1

rmdir /s /q D:\games\Steam\SteamApps\workshop\content\324810\603855831
mkdir D:\games\Steam\SteamApps\workshop\content\324810\603855831
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Workshop\*MutatH0r* /s
del D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Workshop\*PredatH0r* /s

if %error%==0 goto :eof
pause
:eof
