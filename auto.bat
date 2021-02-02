rem EXAMPLES
rem First line saves 1 minute of live stream - from 05:00am to 05:01am
rem Second line saves 30 minutes of live stream - from 15:00pm to 15:30pm

powershell "& '%CD%\ee.record_bbc2.ps1' 0500 1"
powershell "& '%CD%\ee.record_bbc2.ps1' 1500 30"

pause & exit