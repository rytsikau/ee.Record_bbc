'--------------------------------------------------------------------------------------------------'
' ee.Record_bbc2 (v.20210325)                                                                      '
'--------------------------------------------------------------------------------------------------'
set-executionpolicy unrestricted -scope currentuser
$erroractionpreference = "silentlycontinue"; remove-variable *; $erroractionpreference = "continue"
$dtScript = get-date

# Stream parameters
$seqDuration = 6400
$dtRefer = [datetime]::ParseExact('20210101-000000','yyyyMMdd-HHmmss', $null)
$seqReferUTC = 251478003
$timeZoneOffset = [int]($(Get-TimeZone).BaseUtcOffset.TotalMilliseconds / $seqDuration)
$seqRefer = $seqReferUTC - $timeZoneOffset
$urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/" `
    + "bbc_radio_two/bbc_radio_two.isml/dash/bbc_radio_two-audio=96000.dash"
$urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/" `
    + "bbc_radio_two/bbc_radio_two.isml/dash/bbc_radio_two-audio=96000-[seqNumber].m4s"

# Save parameters
$fileName = "bbc_radio_two_[start]_[duration]min.mp4"
$pathSave = (get-item $psscriptroot).fullname + "\recordings"
if (!(test-path $pathSave)) { new-item -itemtype directory $pathSave | out-null }
$durationDefault = 60


# FUNCTION OF DOWNLOADING
#<#-------------------------------------------------------------------------------------------------
function Downloader($seqBegin, $seqEnd, $fileName)
{
    $fileNameTmp = $fileName.Replace(".mp4", "_TMP$(Get-Random).mp4")
    $fs = [System.IO.File]::OpenWrite("$pathSave\$fileNameTmp")

    $fs.Position = $fs.Length
    $content = (New-Object System.Net.WebClient).DownloadData($urlInit)
    $fs.Write($content, 0, $content.Length)

    for ($i = $seqBegin; $i -le $seqEnd; $i++)
    {
        $fs.Position = $fs.Length
        $content = (New-Object System.Net.WebClient).DownloadData($urlSeq.Replace("[seqNumber]", $i))
        $fs.Write($content, 0, $content.Length)

        $span = (new-timespan $dtRefer $(get-date)).TotalMilliseconds / $seqDuration
        $seqCurrent = $seqRefer + $span
        if ($i -gt $seqCurrent) { start-sleep -milliseconds $seqDuration }
    }

    $fs.Close()

    Rename-Item "$pathSave\$fileNameTmp" -NewName $fileName
}
#-------------------------------------------------------------------------------------------------#>


"$(get-date) / 1. Parse START - 1st argument [HHmm]"
#<#-------------------------------------------------------------------------------------------------
if (($args[0] -like "default") -or ($args[0] -like ""))
{
    $dtStart = $dtScript
}
else
{
    try
    {
        $dtStart = [datetime]::ParseExact($args[0],'HHmm', $null)
        if ($(get-date) -lt $dtStart) { $dtStart = $dtStart.AddDays(-1) }
    }
    catch
    {
        write-host "Error! Check START - 1st argument [HHmm]"
        exit
    }
}
#-------------------------------------------------------------------------------------------------#>


"$(get-date) / 2. Parse DURATION - 2nd argument [minutes]"
#<#-------------------------------------------------------------------------------------------------
if (($args[1] -like "default") -or ($args[1] -like ""))
{
    $tsDuration = [timespan]::FromMinutes($durationDefault)
}
else
{
    try
    {
        $tsDuration = [timespan]::FromMinutes($args[1])
    }
    catch
    {
        write-host "Error! Check DURATION - 2nd argument [minutes]"
        exit
    }
}
#-------------------------------------------------------------------------------------------------#>


"$(get-date) / 3. Generate file name, check if it exists"
#<#-------------------------------------------------------------------------------------------------
$fileName = $fileName.Replace("[start]", $dtStart.ToString("yyyyMMdd-HHmm"))
$fileName = $fileName.Replace("[duration]", $tsDuration.TotalMinutes.ToString('0000'))
if (test-path "$pathSave\$fileName")
{
    write-host "Error! File already exists"
    exit
}
#-------------------------------------------------------------------------------------------------#>


"$(get-date) / 4. Calculate first and last sequences"
#<#-------------------------------------------------------------------------------------------------
$seqBegin = [int]($seqRefer + (new-timespan $dtRefer $dtStart).TotalMilliseconds / $seqDuration)
$numberOfSequences = [int]($tsDuration.TotalMilliseconds / $seqDuration)
$seqEnd = $seqBegin + $numberOfSequences - 1
#-------------------------------------------------------------------------------------------------#>


"$(get-date) / 5. Download media"
#<#-------------------------------------------------------------------------------------------------
write-host "    saving: $fileName"
Downloader $seqBegin $seqEnd $fileName
#-------------------------------------------------------------------------------------------------#>


"$(get-date) / 6. Finished!"
#<#-------------------------------------------------------------------------------------------------
$erroractionpreference = "silentlycontinue"; remove-variable *; $erroractionpreference = "continue"
#-------------------------------------------------------------------------------------------------#>