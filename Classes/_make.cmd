@echo off
cd /d "%~dp0"
set cwd=%cd%
cd ..\..\..\..
set TOXIKK=%cd%
cd "%cwd%"

if "%1"=="compress" goto compress

:build
copy ..\Content\MutatH0r_Content.upk %TOXIKK%\UDKGame\Content >nul
if errorlevel 1 goto error
%TOXIKK%\Binaries\Win32\TOXIKK.exe make -configsubdir=LocalBuild
if errorlevel 1 goto error
goto :eof

:compress
cd %TOXIKK%\UDKGame\Script_LocalBuild
if errorlevel 1 goto error
%TOXIKK%\Binaries\Win32\TOXIKK.exe stripsource MutatH0r.u -configsubdir=LocalBuild
if errorlevel 1 goto error
goto :eof

:error
pause

:eof