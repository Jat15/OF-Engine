@echo off

if %PROCESSOR_ARCHITECTURE%==AMD64 (
    if exist bin\OF_Client_Windows-AMD64.exe (
        SET CCARCH=AMD64
        goto :run
    ) else (
        if exist bin\OF_Client_Windows-x86.exe (
            SET CCARCH=x86
            goto :run
        ) else (
            pause
            echo "No server executable found for %PROCESSOR_ARCHITECTURE%."
            echo "You can either compile it yourself (and if possible, send to developers)"
            echo "or wait until we get official binaries for %PROCESSOR_ARCHITECTURE%."
            goto :finish
        )
    )
) else (
    if exist bin\OF_Client_Windows-x86.exe (
        SET CCARCH=x86
        goto :run
    ) else (
        echo "No server executable found for %PROCESSOR_ARCHITECTURE%."
        echo "You can either compile it yourself (and if possible, send to developers)"
        echo "or wait until we get official binaries for %PROCESSOR_ARCHITECTURE%."
        pause
        goto :finish
    )
)

:run

SET PYVER=%SYSTEMDRIVE%\Python26

SET OLD_PATH=%PATH%
SET PATH=%PYVER%;src\windows\sdl_vcpp\lib;src\windows\sdl_image\lib;src\windows\sdl_mixer\lib;%PATH%

SET OLD_PYTHONHOME=%PYTHONHOME%
SET PYTHONHOME=%PYVER%\lib;%PYVER%\DLLs;%PYTHONHOME%

SET OLD_PYTHONPATH=%PYTHONPATH%
SET PYTHONHOME=%PYVER%\lib;%PYVER%\DLLs;%PYTHONHOME%

bin\OF_Server_Windows-%CCARCH%.exe "-q$HOME\OctaForge" -gWARNING %*

echo "To save the output, add     > out_server 2>&1"

:finish
SET PATH=%OLD_PATH%
SET PYTHONHOME=%OLD_PYTHONHOME%
SET PYTHONPATH=%OLD_PYTHONPATH%

