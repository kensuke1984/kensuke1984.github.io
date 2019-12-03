@echo off

rem java -version && msg "%username%" You may have Java installed. || msg "%username%" Get the latest Oracle JDK. & start https://www.oracle.com/technetwork/java/javase/downloads/index.html

reg query "HKEY_LOCAL_MACHINE\SOFTWARE\JavaSoft" >nul 2>&1 && msg "%username%" You may have Java installed. || (msg "%username%" Get the latest Oracle JDK. & start https://www.oracle.com/technetwork/java/javase/downloads/index.html)