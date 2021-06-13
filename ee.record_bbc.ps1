<#-------------------------------------------------------------------------------------------------
ee.record_bbc (v.20210613)
-------------------------------------------------------------------------------------------------#>
set-executionpolicy unrestricted -scope currentuser
$erroractionpreference = "silentlycontinue"; remove-variable *; $erroractionpreference = "continue"
$folder = (get-item $psscriptroot).fullname + "\recordings"
$filename = "[stream]_[start]_[duration]m"
$format = "mp4"
$durationDefault = 60


# FUNCTION TO DOWNLOAD
#<#-------------------------------------------------------------------------------------------------
function Downloader($seqBegin, $seqEnd, $seqCurrent, $filename)
{
    write-host "Saving `"$filename.$format`" 00%" -nonewline
    $filenameTmp = $filename + "_TMP$(get-random)"
    $fs = [System.IO.File]::OpenWrite("$folder\$filenameTmp.$format")
    $fs.position = $fs.length
    $content = (New-Object System.Net.WebClient).downloaddata($urlInit)
    $fs.write($content, 0, $content.length)

    $seqBuffered = $seqCurrent - 5
    if ($seqBegin -gt $seqBuffered)
    {
        $waitBuffering = ($seqBegin - $seqBuffered) * $seqDuration
        start-sleep -milliseconds $waitBuffering
    }

    $percStep = ($seqEnd - $seqBegin) / 100
    for ($i = $seqBegin; $i -lt $seqEnd; $i++)
    {
        if ($i -gt $seqBuffered++) { start-sleep -milliseconds $seqDuration }
        $fs.position = $fs.length
        $content = (New-Object System.Net.WebClient).downloaddata($urlSeq.replace("[seqNumber]", $i))
        $fs.write($content, 0, $content.length)

        $percProgress = [int](($i - $seqBegin) / $percStep)
        $percProgressStr = $percProgress.tostring('00') + "%"
        write-host -nonewline "`b`b`b$percProgressStr";
    }
    write-host "`b`b`bREADY"

    $fs.close()
    rename-item "$folder\$filenameTmp.$format" -newname "$folder\$filename.$format"
}
#-------------------------------------------------------------------------------------------------#>


# FUNCTION TO CREATE MENU
#<#-------------------------------------------------------------------------------------------------
function Create-Menu ($menuTitle, $menuOptions)
{
    # Original function by <josiahdeal3479> is here:
    # https://community.spiceworks.com/scripts/show/4656

    [console]::cursorvisible = $false
    $maxValue = $menuOptions.count - 1
    $selection = 0

    while ($true)
    {
        clear-host
        write-host "$menuTitle"

        for ($i = 0; $i -le $maxValue; $i++)
        {
            if ($i -eq $selection)
            {
                write-host "  $($menuOptions[$i].padright(25," "))" -backgroundcolor darkblue
            }
            else
            {
                write-host "  $($menuOptions[$i])"
            }
        }

        switch ($host.ui.rawui.readkey("NoEcho,IncludeKeyDown").virtualkeycode)
        {
            40 {
                    if ($selection -eq $maxValue) { $selection = 0 }
                    else { $selection += 1 }
                    break
               }

            38 {
                    if ($selection -eq 0) { $selection = $maxValue }
                    else { $selection -= 1 }
                    break
               }

            13 {
                    [Console]::CursorVisible = $true
                    $stream = $menuOptions[$selection].replace(" ", "_").tolower()
                    return $stream
               }
        }
    }
}
#-------------------------------------------------------------------------------------------------#>


# 1. Get arguments
#<#-------------------------------------------------------------------------------------------------
if ($args[0] -like "")
{
    $menuTitle = "Select STREAM"
    $menuOptions = "BBC Radio One",
                   "BBC Radio Two",
                   "BBC Radio Three"
    $streamStr = Create-Menu $menuTitle $menuOptions

    write-host "Select START"
    write-host "  To record from now, just press ENTER"
    write-host "  Type the start time as [HHmm], in 24-hour format:"
    write-host "  " -nonewline
    $startStr = read-host

    write-host "Select DURATION"
    write-host "  To use default 60 minutes, just press ENTER"
    write-host "  Type required duration in minutes:"
    write-host "  " -nonewline
    $durationStr = read-host
}
else
{
    $streamStr = $args[0]
    $startStr = $args[1]
    $durationStr = $args[2]
}
#-------------------------------------------------------------------------------------------------#>


# 2. Parse STREAM (1st argument) and assign its variable(s)
#<#-------------------------------------------------------------------------------------------------
if ($streamStr -eq "bbc_radio_one")
{
    $dtReferUtcStr = "20210101-000000"
    $seqReferUtc = 251478007
    $seqDuration = 6400
    $urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_" `
        + "one/bbc_radio_one.isml/dash/bbc_radio_one-audio=96000.dash"
    $urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/bbc_radio_" `
        + "one/bbc_radio_one.isml/dash/bbc_radio_one-audio=96000-[seqNumber].m4s"
}
elseif ($streamStr -eq "bbc_radio_two")
{
    $dtReferUtcStr = "20210101-000000"
    $seqReferUtc = 251478007
    $seqDuration = 6400
    $urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_" `
        + "two/bbc_radio_two.isml/dash/bbc_radio_two-audio=96000.dash"
    $urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/bbc_radio_" `
        + "two/bbc_radio_two.isml/dash/bbc_radio_two-audio=96000-[seqNumber].m4s"
}
elseif ($streamStr -eq "bbc_radio_three")
{
    $dtReferUtcStr = "20210101-000000"
    $seqReferUtc = 251478007
    $seqDuration = 6400
    $urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_" `
        + "three/bbc_radio_three.isml/dash/bbc_radio_three-audio=96000.dash"
    $urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/bbc_radio_" `
        + "three/bbc_radio_three.isml/dash/bbc_radio_three-audio=96000-[seqNumber].m4s"
}
else
{
    write-host "Error! Check STREAM (1st argument)"
    exit
}
#-------------------------------------------------------------------------------------------------#>


# 3. Parse START (2nd argument) and assign its variable(s)
#<#-------------------------------------------------------------------------------------------------
if ($startStr -like "")
{
    $start = get-date
}
else
{
    try
    {
        $start = [datetime]::ParseExact($startStr,'HHmm', $null)
        if ($(get-date) -lt $start) { $start = $start.adddays(-1) }
    }
    catch
    {
        write-host "Error! Check START (2nd argument)"
        exit
    }
}
#-------------------------------------------------------------------------------------------------#>


# 4. Parse DURATION (3rd argument) and assign its variable(s)
#<#-------------------------------------------------------------------------------------------------
if ($durationStr -like "")
{
    $duration = [timespan]::FromMinutes($durationDefault)
}
else
{
    try
    {
        $duration = [timespan]::FromMinutes($durationStr)
    }
    catch
    {
        write-host "Error! Check DURATION (3rd argument)"
        exit
    }
}
#-------------------------------------------------------------------------------------------------#>


# 5. Generate file name, check if it exists
#<#-------------------------------------------------------------------------------------------------
$filename = $filename.Replace("[stream]", $streamStr)
$filename = $filename.Replace("[start]", $start.ToString("yyyyMMdd-HHmm"))
$filename = $filename.Replace("[duration]", $duration.TotalMinutes.ToString('0000'))
if (test-path "$folder\$filename.$format")
{
    write-host "Error! File already exists"
    exit
}
elseif (!(test-path $folder))
{
    new-item -itemtype directory $folder | out-null
}
#-------------------------------------------------------------------------------------------------#>


# 6. Calculate sequences
#<#-------------------------------------------------------------------------------------------------
$dtReferUtc = [datetime]::ParseExact($dtReferUtcStr,"yyyyMMdd-HHmmss", $null)
$dtStartUtc = $start.ToUniversalTime()
$seqBegin = [int]($seqReferUtc +
    (new-timespan $dtReferUtc $dtStartUtc).TotalMilliseconds / $seqDuration)
$seqEnd = $seqBegin + [int]($duration.TotalMilliseconds / $seqDuration)
$seqCurrent = [int]($seqReferUtc +
    (new-timespan $dtReferUtc $(get-date).ToUniversalTime()).TotalMilliseconds / $seqDuration)
#-------------------------------------------------------------------------------------------------#>


# 7. Download media
#<#-------------------------------------------------------------------------------------------------
Downloader $seqBegin $seqEnd $seqCurrent $filename
#-------------------------------------------------------------------------------------------------#>


# 8. Finish
#<#-------------------------------------------------------------------------------------------------
$erroractionpreference = "silentlycontinue"; remove-variable *; $erroractionpreference = "continue"
#-------------------------------------------------------------------------------------------------#>
