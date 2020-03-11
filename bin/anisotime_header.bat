@echo off
rem v0.0.1
rem copy /b anisotime_header.bat+kibrary.jar anisotime.bat
java -Xmx2g -cp "%~f0" io.github.kensuke1984.anisotime.ANISOtime %*
exit /b %ERRORLEVEL%
