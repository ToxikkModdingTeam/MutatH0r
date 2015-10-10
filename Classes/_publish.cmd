@echo off
cd /d %~dp0
setlocal
set error=0
"c:\program files\7-Zip\7z.exe" a -tzip MutatH0r_Source.zip *.uc
if errorlevel 1 set error=1
copy ..\..\..\..\UDKGame\Script\MutatH0r.u .
if errorlevel 1 set error=1
copy MutatH0r.u D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\CookedPC
if errorlevel 1 set error=1
copy UDKMutatH0r.ini D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config
copy UDKMutatH0r.ini D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\DedicatedServer1
copy UDKMutatH0r.ini D:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config\DedicatedServer2
if errorlevel 1 set error=1
if %error%==0 goto :eof
pause
:eof
