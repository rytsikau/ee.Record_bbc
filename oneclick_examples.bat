rem EXAMPLES TO SAVE A STREAM IN ONE CLICK

rem To download 5 minutes of "BBC Radio One" from 05:00am to 05:15am:
powershell "& '%CD%\ee.record_bbc.ps1' bbc_radio_one 0500 5"

rem To download 1 hour of "BBC Radio Two" from 03:00pm to 04:00pm:
powershell "& '%CD%\ee.record_bbc.ps1' bbc_radio_two 1500"

rem To record "BBC Radio Three" in real time for 1 hour:
powershell "& '%CD%\ee.record_bbc.ps1' bbc_radio_three"

pause