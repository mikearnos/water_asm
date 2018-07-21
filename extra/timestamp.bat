@echo off

for /f "tokens=2-4 delims=/ " %%a in ('date /T') do set year=%%c
for /f "tokens=2-4 delims=/ " %%a in ('date /T') do set day=%%a
for /f "tokens=2-4 delims=/ " %%a in ('date /T') do set month=%%b

for /f "tokens=1 delims=: " %%h in ('time /T') do set hour=%%h
for /f "tokens=2 delims=: " %%m in ('time /T') do set minutes=%%m
for /f "tokens=3 delims=: " %%a in ('time /T') do set ampm=%%a

echo .db	"~{ %day%/%month%/%year% %hour%:%minutes%%ampm% " >extra\timestamp.txt
type extrainfo.txt >> extra\timestamp.txt
