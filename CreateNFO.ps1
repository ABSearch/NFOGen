
# FUNCTIONS #
    function search_duckduckgo($ep01) {
        $ie = New-Object -ComObject "InternetExplorer.Application"
        $ie.Visible = $true
        $ie.Navigate("https://duckduckgo.com/?q=\$ep01 site:imdb.com/title")
        while ($ie.ReadyState -ne 4) {Start-Sleep -Milliseconds 1000}
        $url = $ie.LocationURL
        Write-Output $url
        $ie.Quit()
    }

    function Tag1Function {
        $global:option1 = "[/size][/b][img]https://i.imgur.com/7IYWhhj.jpg[/img]"                               #ADD Uploader TAG Img
        $global:option2 = "[color=grey][i]you wouldn't download a car[/i][/color][/center]"                     #ADD Uploader TAG
        $option1 > $null; $option2 > $null
    }

    function Tag2Function {
        $global:option1 = "[/size][/b][img]https://i.imgur.com/vdFjWnB.jpg[/img]"                               #ADD Uploader TAG Img
        $global:option2 = '[color=grey][i]“F**k yes I would. Sign me up[/i][/color][/center]'                   #ADD Uploader TAG
        $option1 > $null; $option2 > $null
    }


    # PRECHECK #
    if (Test-Path '*.mkv') { $filetype = 'mkv' } elseif (Test-Path -Path '*.mp4') { $filetype = 'mp4' }         # CHECK FOR Filetypes.
    else { Clear-Host; Write-Output "No MP4, AVI, or MKV found"; Exit }                             #iF NO Filetypes, error
    if (Test-Path "url.txt") { if ((Get-Content "url.txt" | Measure-Object).Count -ne 0) { $imdbUrl = Get-Content "url.txt"; Write-Output "url.txt found`n"; }  # CHECK if URL exists/isnt empty
    else { Write-Output "url.txt is empty`n" } }


# -- SELECT TAG #
    Write-Host "Which profile are we using:"; Write-Host "1. PoF"; Write-Host "2. SiQ"
    $2input = Read-Host; if ($2input -eq "1") { Tag1Function } elseif ($2input -eq "2") {Tag2Function } else { Write-Host "Invalid selection" }


# PREPERATION #
    $ProgressPreference = 'SilentlyContinue'                                                        # MAKES DOWNLOADS SiLENT
    #$foldername = (Get-Item .).Name                                                                # SET $foldername To Current-Dir
    $foldername = if ($foldername -match "Season") { (Split-Path -Path (Split-Path -Parent (Get-Location)) -Leaf) } # IF Foldername contains Season, set to parent
    else { (Split-Path -Path (Get-Location) -Leaf) }                                                # SET $foldername To Current-Dir
    $final = "$((Get-Item .).Name -replace ' ', '.').txt"                                           # SET $finalfile To Current-Dir
    $cli = "C:\cli"                                                                                 # SET DLL/TMP Directory
    Remove-Item "$cli\tmpdir" -Recurse -Force -ErrorAction Ignore                                   # DELETE OLD $tmp dir
    $tmp = (New-Item "$cli\tmpdir" -ItemType Directory -ErrorAction Ignore).FullName                # CREATE NEW $tmp dir
    $ep01 = Get-ChildItem -Filter "*.$filetype" -Name | Select-Object -First 1                      # SELECTS THE fist file
    $count = (Get-ChildItem -Filter "*.$filetype").Count                                            # COUNT How many episodes there are
    $omapi = "cebd9b53"; $imapi = "58656d49a2aa407";                                                #IMDB AND OMDB API KEYS (Stolen from google)


# PRE PROCESS #
    if ((Get-ChildItem -Filter "*.$filetype").Count -lt 2) { $imdbUrl = search_duckduckgo($ep01) }  # GUESS IMDB URL if less then 2 files
    $durr = & "$cli\mediainfo" "--Output=General;%Duration%" "$ep01"                                # READ VIDEO LENGTH #
    $t1 = [int]($durr / 1000 * 0.25); $t2 = [int]($durr / 1000 * 0.5); $t3 = [int]($durr / 1000 * 0.75)     # SET SCREENSHOT TIMES: through variables


#iMAGE-POSTER: Get From IMDB URL
    Clear-Host; if (-not $imdbUrl) { do { $imdbUrl = Read-Host "IMDB URL: " } while ($imdbUrl -eq "") }
    Clear-Host;Write-Output "Working on it. Sit tight."                                             # BEGINS The whole thing
    $imdbId = [regex]::Match($imdbUrl, 'tt\d+').Value                                               # SELECTS The IMDB ID from the URL
    $posterUrl = Invoke-RestMethod -uri "omdbapi.com/?i=$imdbId&apikey=$omapi"                      # EXTRACTS cover from OMDB. Keys 852159f0/cebd9b53
    Invoke-WebRequest -Uri ($posterUrl.Poster -replace '300.jpg', '900.jpg') -OutFile "$tmp\imdb.jpg"   # SAVES the Image.
    $imgimdb = $(Invoke-RestMethod -Uri 'https://api.imgur.com/3/image' -Method 'POST' -Headers @{'Authorization'="Client-ID $imapi"} -InFile "$tmp\imdb.jpg").data.link   # UPLOAD to IMGUR


# -- BEGiN WRiTING TO NFO -- #
    Add-Content $final ("[center][size=3][b]$foldername[/size][/b]`n`n[img]$imgimdb[/img]`n")       # RELEASE TiTLE AND iMAGE
    Add-Content $final ("[img]https://i.imgur.com/NgmVlUS.png[/img][/center][size=3][b]`n")         # iNFO TAG: Center Start, Size Start, Bold Start:
    Add-Content $final ("RELEASE: $foldername`n")   # iNFO TAG:                                     # RELEASE TiTLE
    if ((Get-ChildItem -Filter "*.$filetype").Count -gt 1) { Add-Content $final ("EPISODES: $count`n") }  # EPiSODES (MAY BE BROKEN. I ADDED IN $FILETYPE AND THE PERIOD)
    if ($filetype -eq "mkv") { $mnfo = "General" } else { $mnfo = "Video" }                         # Some MKV's don't have bitrate, so it pulls overall bitrate 
    Add-Content $final (& "$cli\mediainfo" "--Output=$mnfo;ViDEO: %BitRate/String%" "$ep01")        # WRITE Bitrate
    Add-Content $final ""                                                                           # SPACE
    Add-Content $final (& "$cli\mediainfo" "--Output=Video;RESOLUTiON: %Width%x%Height%" "$ep01")   # WRITE Resolution
    Add-Content $final ""                                                                           # SPACE
    Add-Content $final (("AUDIO: " + (& "$cli\mediainfo" "--Output=Audio;[%BitRate/String%, ][%Format%, ][%Channel(s)/String%]" "$ep01"))) #AUDIO Info
    Add-Content $final "`nLANGUAGE: ENGLiSH`n"                                                      # LANGUAGE
    Add-Content $final -Value ("FiLETYPE: " + $filetype.ToUpper() + "`n")                           # FiLETYPE
    Add-Content $final "ENCODER: WhoRU`n"                                                             # ENCODER
    Add-Content $final "SOURCE: Personal Rips / Mixed WEB-DL`n"                                     # SOURCE
    Add-Content $final "NOTES: Enjoy.`n"                                                            # NOTES
    Add-Content $final "[center]https://www.imdb.com/title/$imdbId/`n"                              # iMDB URL
    Add-Content $final "[img]https://i.imgur.com/PctR4uM.png[/img]`n"                               # PLOT TAG
    Add-Content $final ((Invoke-RestMethod -uri "https://www.omdbapi.com/?i=$imdbId&apikey=$omapi").plot)    #PLOT
    Add-Content $final "`n[img]https://i.imgur.com/f2VBD7y.png[/img]`n"                               # SCREENS Head


# -- SCREENSHOTS -- #
& "$cli\ffmpeg" -skip_frame nokey -ss "$t1.00" -i "$ep01" -frames:v 1 "$tmp\01.png"             #SCREENSHOT1
& "$cli\ffmpeg" -skip_frame nokey -ss "$t2.00" -i "$ep01" -frames:v 1 "$tmp\02.png"             #SCREENSHOT2
& "$cli\ffmpeg" -skip_frame nokey -ss "$t3.00" -i "$ep01" -frames:v 1 "$tmp\03.png";Clear-Host  #SCREENSHOT3
if (-not (Test-Path "$tmp\03.png")) {Clear-Host; Write-Output "Screenshots are missing "; Exit} #CHECKS If screenshots are missing
$img1 = $(Invoke-RestMethod -Uri 'https://api.imgur.com/3/image' -Method 'POST' -Headers @{'Authorization'="Client-ID $imapi"} -InFile "$tmp\01.png").data.link   # UPLOADS The Image to IMGUR
$img2 = $(Invoke-RestMethod -Uri 'https://api.imgur.com/3/image' -Method 'POST' -Headers @{'Authorization'="Client-ID $imapi"} -InFile "$tmp\02.png").data.link   # UPLOADS The Image to IMGUR
$img3 = $(Invoke-RestMethod -Uri 'https://api.imgur.com/3/image' -Method 'POST' -Headers @{'Authorization'="Client-ID $imapi"} -InFile "$tmp\03.png").data.link   # UPLOADS The Image to IMGUR
Add-Content $final "[img]$img1[/img]`n"                                                         #ADD SCREENSHOT 1
Add-Content $final "[img]$img2[/img]`n"                                                         #ADD SCREENSHOT 2
Add-Content $final "[img]$img3[/img]`n"                                                         #ADD SCREENSHOT 3
Add-Content $final "$option1"; Add-Content $final "$option2"                                    #ADD TAG Part 2


# -- CLEANUP -- #
Remove-Item "$cli\tmpdir" -Recurse -Force -ErrorAction Ignore                                   # DELETE OLD $tmp dir