@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set NAME=NESDungeone

del %NAME%.o %NAME%.nes %NAME%.map.txt %NAME%.labels.txt %NAME%.nes.ram.nl %NAME%.nes.0.nl %NAME%.nes.1.nl %NAME%.nes.dbg 2>nul
del *.o 2>nul

echo.
echo Locating cc65...
set "CC65_BIN="

rem 
if defined CC65_HOME if exist "%CC65_HOME%\bin\ca65.exe" (
    set "CC65_BIN=%CC65_HOME%\bin\"
    goto found
)

rem Already on PATH
where ca65 >nul 2>nul && goto found

rem  Common install locations
for %%d in (
    "\cc65\bin"
    "C:\cc65\bin"
    "%ProgramFiles%\cc65\bin"
    "%ProgramFiles(x86)%\cc65\bin"
    "%USERPROFILE%\cc65\bin"
    "%LOCALAPPDATA%\cc65\bin"
) do (
    if exist "%%~d\ca65.exe" (
        set "CC65_BIN=%%~d\"
        goto found
    )
)

echo Could not find cc65. Add its bin folder to PATH or set CC65_HOME.
goto failure

:found
echo.
if defined CC65_BIN (
    echo Using cc65 in "%CC65_BIN%"
) else (
    echo Using cc65 from PATH
)
echo.
echo Compiling...
set OBJS=
set BUILD_FAILED=
for %%f in (*.s) do (
    echo   %%f
    "%CC65_BIN%ca65" "%%f" -g -o "%%~nf.o"
    if errorlevel 1 set BUILD_FAILED=1
    set OBJS=!OBJS! "%%~nf.o"
)
if defined BUILD_FAILED goto failure

echo.
echo Linking...
"%CC65_BIN%ld65" -o %NAME%.nes -C %NAME%.cfg !OBJS! -m %NAME%.map.txt -Ln %NAME%.labels.txt --dbgfile %NAME%.nes.dbg
if errorlevel 1 goto failure

echo.
echo Success!
goto endbuild

:failure
echo.
echo Build error!

:endbuild
endlocal