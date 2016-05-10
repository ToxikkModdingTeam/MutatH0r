@echo off
cd /d %~dp0
setlocal
set error=0
"c:\program files\7-Zip\7z.exe" a -tzip MutatH0r_Source.zip *.uc *.ini
if errorlevel 1 set error=1
copy ..\..\..\..\UDKGame\Script\MutatH0r.u .
if errorlevel 1 set error=1
copy ..\..\..\..\UDKGame\Script\PredatH0r.u .
if errorlevel 1 set error=1
copy MutatH0r.u f:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Script
if errorlevel 1 set error=1
copy PredatH0r.u f:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Script
if errorlevel 1 set error=1
copy UDKMutatH0r.ini f:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config
if errorlevel 1 set error=1
copy UDKPredatH0r.ini f:\games\Steam\SteamApps\common\TOXIKK\UDKGame\Config
if errorlevel 1 set error=1

mkdir f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\ 2>nul
mkdir f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\Script 2>nul
mkdir f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\Content 2>nul
mkdir f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\Config 2>nul
copy MutatH0r.u f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\Script
if errorlevel 1 set error=1
copy MutatH0r_Content.upk f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\Content
if errorlevel 1 set error=1
copy UDKMutatH0r.ini f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent\Config
if errorlevel 1 set error=1

if %error%==0 goto :eof
pause
:eof
