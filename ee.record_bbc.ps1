<#-------------------------------------------------------------------------------------------------
ee.Record_bbc (v.20210614b)
-------------------------------------------------------------------------------------------------#>
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
$ErrorActionPreference = "SilentlyContinue"; Remove-Variable *; $ErrorActionPreference = "Continue"
$folder = (Get-Item $PSScriptRoot).FullName + "\recordings"
$filename = "[stream]_[start]_[duration]m"
$format = "m4a"
$durationDefault = 60


# Function to download
#<#-------------------------------------------------------------------------------------------------
Function Downloader($seqBegin, $seqEnd, $seqCurrent, $filename)
{
    Write-Host "Saving `'$filename.$format`'...   0%" -NoNewline
    $filenameTmp = $filename + "_TMP$(Get-Random)"
    $fs = [System.IO.File]::OpenWrite("$folder\$filenameTmp.$format")
    $fs.Position = $fs.Length
    $content = (New-Object System.Net.WebClient).DownloadData($urlInit)
    $fs.Write($content, 0, $content.Length)

    $seqBuffered = $seqCurrent - 5
    If ($seqBegin -gt $seqBuffered)
    {
        $waitBuffering = ($seqBegin - $seqBuffered) * $seqDuration
        Start-Sleep -Milliseconds $waitBuffering
    }

    $percStep = ($seqEnd - $seqBegin) / 100
    For ($i = $seqBegin; $i -lt $seqEnd; $i++)
    {
        If ($i -gt $seqBuffered++) { Start-Sleep -Milliseconds $seqDuration }
        $fs.Position = $fs.Length
        $content = (New-Object System.Net.WebClient).DownloadData($urlSeq.Replace("[seqNumber]", $i))
        $fs.Write($content, 0, $content.Length)

        $percProgress = [int](($i - $seqBegin) / $percStep)
        $percProgressStr = $percProgress.ToString().PadLeft(3,' ') + "%"
        Write-Host -NoNewline "`b`b`b`b$percProgressStr";
    }
    Write-Host "`b`b`b`bREADY"

    $fs.Close()
    Rename-Item "$folder\$filenameTmp.$format" -NewName "$folder\$filename.$format"
}
#-------------------------------------------------------------------------------------------------#>


# Function to create menu
#<#-------------------------------------------------------------------------------------------------
Function Create-Menu ($menuTitle, $menuOptions)
{
    # Original function by <josiahdeal3479> is here:
    # https://community.spiceworks.com/scripts/show/4656

    [Console]::CursorVisible = $False
    $maxValue = $menuOptions.Count - 1
    $selection = 0

    While ($True)
    {
        Clear-Host
        Write-Host $menuTitle

        For ($i = 0; $i -le $maxValue; $i++)
        {
            If ($i -eq $selection)
            {
                Write-Host "  $($menuOptions[$i].PadRight(25," "))" -BackgroundColor DarkBlue
            }
            Else
            {
                Write-Host "  $($menuOptions[$i])"
            }
        }

        Switch ($Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").VirtualKeyCode)
        {
            40 {
                    If ($selection -eq $maxValue) { $selection = 0 }
                    Else { $selection += 1 }
                    Break
               }

            38 {
                    If ($selection -eq 0) { $selection = $maxValue }
                    Else { $selection -= 1 }
                    Break
               }

            13 {
                    [Console]::CursorVisible = $True
                    $stream = $menuOptions[$selection].Replace(" ", "_").ToLower()
                    Return $stream
               }
        }
    }
}
#-------------------------------------------------------------------------------------------------#>


# 1. Get arguments
#<#-------------------------------------------------------------------------------------------------
If ($Args[0] -like "")
{
    $menuTitle = "Select STREAM"
    $menuOptions = "BBC Radio One", "BBC Radio Two", "BBC Radio Three"
    $streamStr = Create-Menu $menuTitle $menuOptions

    Write-Host "Select START"
    Write-Host "  [to record from now, just press ENTER]"
    Write-Host "  Type the start time as [HHmm], in 24-hour format:"
    Write-Host "  " -NoNewline
    $startStr = Read-Host

    Write-Host "Select DURATION"
    Write-Host "  [to use default 60 minutes, just press ENTER]"
    Write-Host "  Type required duration in minutes:"
    Write-Host "  " -NoNewline
    $durationStr = Read-Host
}
Else
{
    $streamStr = $Args[0]
    $startStr = $Args[1]
    $durationStr = $Args[2]
}
#-------------------------------------------------------------------------------------------------#>


# 2. Parse STREAM (1st argument) and assign its variable(s)
#<#-------------------------------------------------------------------------------------------------
If ($streamStr -eq $menuOptions[0].Replace(" ", "_").ToLower())
{
    $dtReferUtcStr = "20210101-000000"
    $seqReferUtc = 251478007
    $seqDuration = 6400
    $urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_" `
        + "one/bbc_radio_one.isml/dash/bbc_radio_one-audio=96000.dash"
    $urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/bbc_radio_" `
        + "one/bbc_radio_one.isml/dash/bbc_radio_one-audio=96000-[seqNumber].m4s"
}
ElseIf ($streamStr -eq $menuOptions[1].Replace(" ", "_").ToLower())
{
    $dtReferUtcStr = "20210101-000000"
    $seqReferUtc = 251478007
    $seqDuration = 6400
    $urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_" `
        + "two/bbc_radio_two.isml/dash/bbc_radio_two-audio=96000.dash"
    $urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/bbc_radio_" `
        + "two/bbc_radio_two.isml/dash/bbc_radio_two-audio=96000-[seqNumber].m4s"
}
ElseIf ($streamStr -eq $menuOptions[2].Replace(" ", "_").ToLower())
{
    $dtReferUtcStr = "20210101-000000"
    $seqReferUtc = 251478007
    $seqDuration = 6400
    $urlInit = "https://as-dash-ww-live.akamaized.net/pool_904/live/ww/bbc_radio_" `
        + "three/bbc_radio_three.isml/dash/bbc_radio_three-audio=96000.dash"
    $urlSeq = "https://as-dash-ww.live.cf.md.bbci.co.uk/pool_904/live/ww/bbc_radio_" `
        + "three/bbc_radio_three.isml/dash/bbc_radio_three-audio=96000-[seqNumber].m4s"
}
Else
{
    Write-Host "Error! Check STREAM (1st argument)"
    Exit
}
#-------------------------------------------------------------------------------------------------#>


# 3. Parse START (2nd argument) and assign its variable(s)
#<#-------------------------------------------------------------------------------------------------
If ($startStr -like "")
{
    $start = Get-Date
}
Else
{
    Try
    {
        $start = [DateTime]::ParseExact($startStr,'HHmm', $Null)
        If ($(Get-Date) -lt $start) { $start = $start.AddDays(-1) }
    }
    Catch
    {
        Write-Host "Error! Check START (2nd argument)"
        Exit
    }
}
#-------------------------------------------------------------------------------------------------#>


# 4. Parse DURATION (3rd argument) and assign its variable(s)
#<#-------------------------------------------------------------------------------------------------
If ($durationStr -like "")
{
    $duration = [TimeSpan]::FromMinutes($durationDefault)
}
Else
{
    Try
    {
        $duration = [TimeSpan]::FromMinutes($durationStr)
    }
    Catch
    {
        Write-Host "Error! Check DURATION (3rd argument)"
        Exit
    }
}
#-------------------------------------------------------------------------------------------------#>


# 5. Generate file name, check if it exists
#<#-------------------------------------------------------------------------------------------------
$filename = $filename.Replace("[stream]", $streamStr)
$filename = $filename.Replace("[start]", $start.ToString("yyyyMMdd-HHmm"))
$filename = $filename.Replace("[duration]", $duration.TotalMinutes.ToString('0000'))
If (Test-Path "$folder\$filename.$format")
{
    Write-Host "Error! File already exists"
    Exit
}
ElseIf (!(Test-Path $folder))
{
    New-Item -ItemType Directory $folder | Out-Null
}
#-------------------------------------------------------------------------------------------------#>


# 6. Calculate sequences
#<#-------------------------------------------------------------------------------------------------
$dtReferUtc = [DateTime]::ParseExact($dtReferUtcStr,"yyyyMMdd-HHmmss", $Null)
$dtStartUtc = $start.ToUniversalTime()
$seqBegin = [int]($seqReferUtc +
    (New-TimeSpan $dtReferUtc $dtStartUtc).TotalMilliseconds / $seqDuration)
$seqEnd = $seqBegin + [int]($duration.TotalMilliseconds / $seqDuration)
$seqCurrent = [int]($seqReferUtc +
    (New-TimeSpan $dtReferUtc $(Get-Date).ToUniversalTime()).TotalMilliseconds / $seqDuration)
#-------------------------------------------------------------------------------------------------#>


# 7. Download media
#<#-------------------------------------------------------------------------------------------------
Downloader $seqBegin $seqEnd $seqCurrent $filename
#-------------------------------------------------------------------------------------------------#>


# 8. Finish
#<#-------------------------------------------------------------------------------------------------
$ErrorActionPreference = "SilentlyContinue"; Remove-Variable *; $ErrorActionPreference = "Continue"
#-------------------------------------------------------------------------------------------------#>
