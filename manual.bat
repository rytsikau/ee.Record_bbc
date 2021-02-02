@echo off
set SCRIPTNAME=ee.record_bbc2
echo %SCRIPTNAME%

echo.
echo START TIME
echo To download any part from the last 24 hours of stream, enter the start time as [HHmm], in 24-hour format
echo To record from now, just press Enter
set /p START=Type start time as [HHmm]: 
if [%START%]==[] set START="default"

echo.
echo DURATION
set /p DURATION=Type required duration in minutes: 
if [%DURATION%]==[] set DURATION="default"

powershell "& '%CD%\%SCRIPTNAME%.ps1' %START% %DURATION%"
pause & exit