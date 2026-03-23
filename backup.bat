@echo off
set NAME=%~dp0$
echo %NAME%
for %%D in ( %NAME:\$=% ) do set NAME=%%~nxD
if exist \BACKUP_DIR.BAT call \BACKUP_DIR.BAT
if not defined BACKUP_DIR set BACKUP_DIR=G:\Backup
set DEST=%BACKUP_DIR%\%NAME%
set WINRAR="%PROGRAMFILES%\WinRAR\RAR"
set DT=%DATE%-%TIME%
set DT=%DT: =0%
for /f "tokens=1-6 delims=./-:" %%c in ("%DT%") do (
	set DT=%%e.%%d.%%c_%%f.%%g.%%h
)
set RARFILE=%DEST%\%NAME%
mkdir %DEST% 2>nul
%WINRAR% u -as -r -tl "%RARFILE%" *.* -x.git
if not %ERRORLEVEL% == 10 copy %RARFILE%.rar %RARFILE%_%DT%.rar
