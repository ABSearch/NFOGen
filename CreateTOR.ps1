
# SET STUFF #
    $cli = "C:\cli"                                                                                             # SET Temp dir
    $tracker = "YOUR TRACKER URL HERE"                                                                          # SET Tracker URL
    $torsave = "Y:\our\Tor\Dir"                                                                                 # SET Tor output dir
    $qbt = "c:/program files/qbittorrent/"                                                                      # SET QBT path

# CONFUSED LOST IF STATEMENT #
    if (Test-Path '*.mkv') { $filetype = 'mkv' } elseif (Test-Path -Path '*.mp4') { $filetype = 'mp4' }         # CHECK FOR Filetypes.

# GET STUFF #
    $currentdir = (Get-Location).path                                                                           # GETS current directory
    $srcparent = Split-Path (Get-Location).path -Parent                                                         # GETS Parent dir path
    $onefile = Get-ChildItem -Filter "*.$filetype" -Name | Select-Object -First 1                               # GETS filename of the first matching file
    $filename = "$((Get-Item .).Name -replace ' ', '.')"                                                        # GETS foldername and replaces spaces wth periods

# CHECK STUFF #
    if ((Get-ChildItem -Filter "*.$filetype").Count -eq 1) { $torout = $onefile; $savepath = $currentdir }      # CHECKS if there is 1 file. Then assumes movie
    if ((Get-ChildItem -Filter "*.$filetype").Count -ne 1) { $torout = $currentdir; $savepath = $srcparent }    # CHECKS if there is 0 or more then 1 file, assumes tv show

# DO STUFF #
    & "$cli\tt\torrenttools" create "$torout" -p -a "$tracker" --exclude "^.*\.ps1$" --no-created-by -o "$torsave\$filename.torrent"                # CREATES The torrent. Skips .ps1 files
    & "$qbt/qbittorrent.exe" "$torsave\$filename.torrent" --add-paused=false --skip-hash-check "--save-path=$savepath"                              # ADDS The torrent to qbittorrent