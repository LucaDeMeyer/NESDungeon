@del NESDungeone.o
@del NESDungeone.nes
@del NESDungeone.map.txt
@del NESDungeone.labels.txt
@del NESDungeone.nes.ram.nl
@del NESDungeone.nes.0.nl
@del NESDungeone.nes.1.nl
@del NESDungeone.nes.dbg
@echo.
@echo Compiling...
\cc65\bin\ca65 NESDungeone.s -g -o NESDungeone.o
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Linking...
\cc65\bin\ld65 -o NESDungeone.nes -C NESDungeone.cfg NESDungeone.o -m NESDungeone.map.txt -Ln NESDungeone.labels.txt --dbgfile NESDungeone.nes.dbg
@IF ERRORLEVEL 1 GOTO failure
@echo.
@echo Success!
@GOTO endbuild
:failure
@echo.
@echo Build error!
:endbuild