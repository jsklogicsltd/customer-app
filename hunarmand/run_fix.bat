@echo off
cd "d:\Antigravity projects\custmer app\hunarmand"
dart fix --apply > fix.log 2>&1
exit /b %ERRORLEVEL%
