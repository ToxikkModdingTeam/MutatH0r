@echo off
cd /d "%~dp0"
setlocal
set error=0

copy ..\..\..\..\UDKGame\Script_LocalBuild\MutatH0r.u .
if errorlevel 1 set error=1
copy ..\..\..\..\UDKGame\Script_LocalBuild\PredatH0r.u .
if errorlevel 1 set error=1

copy d:\sources\ToxikkServerLauncher\ToxikkServerLauncher\MyServerConfig.ini d:\sources\ToxikkServerLauncher\ToxikkServerLauncher\bin\Debug\MyServerConfig.ini 2>nul

for %%d in (f:\games\Steam\SteamApps\common\TOXIKK\UDKGame c:\steamcmd\steamapps\workshop\content\324810\MutatH0r f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent) do (
  for %%e in (Script Content Config) do (
    if not exist %%d\%%e mkdir %%d\%%e
    if errorlevel 1 set error=1
  )
  
  copy MutatH0r.u %%d\Script >nul
  if errorlevel 1 set error=1
  copy MutatH0r_Content.upk %%d\Content >nul
  if errorlevel 1 set error=1 
  copy UDKMutatH0r.ini %%d\Config >nul
  if errorlevel 1 set error=1
  
  if not "%%d" == "f:\games\Steam\SteamApps\common\TOXIKK\WorkshopUploader\MutatH0r\UploadContent" (
    copy PredatH0r.u %%d\Script >nul
    if errorlevel 1 set error=1 
    copy UDKPredatH0r.ini %%d\Config >nul
    if errorlevel 1 set error=1
  )
)
if %error%==0 goto :eof
pause
:eof
