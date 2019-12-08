@echo off

rem msg "%username%" Get the latest Oracle JDK and call me again. & start https://www.oracle.com/technetwork/java/javase/downloads/index.html

java -version >nul 2>&1 && (msg "%username%" You may have Java installed, which is already in PATH. & exit /B 0)

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft" >nul 2>&1 && msg "%username%" You may have Java installed, which is-^>was not in PATH (Please reboot). || (msg "%username%" Get the latest Oracle JDK. & start https://www.oracle.com/technetwork/java/javase/downloads/index.html)

for /f %%A in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft" 2^>nul') do (
    for /f "tokens=1,2*" %%B in ('reg query "%%A" 2^>nul') do (
        if "%%B"=="CurrentVersion" (
          for /f "tokens=1,2*" %%I in ('reg query "%%A\%%D" 2^>nul') do (
              if "%%I"=="JavaHome" (
                set javahome=%%K
              )))))
  
setx path "%javahome%\bin;%path%"