@ECHO OFF
call extra\timestamp.bat
"C:\Program Files (x86)\Atmel\AVR Tools\AvrAssembler2\avrasm2.exe" -S "build\labels.tmp" -fI -W+ie -C V2 -o "bin\water.hex" -d "build\water.obj" -e "bin\water.eep" -m "build\water.map" "water.asm"
call extra\makebin.bat
