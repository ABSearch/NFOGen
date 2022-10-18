	@echo off
	
::SET FOLDER/FiLE Names (final line replaces spaces with periods)
	for %%t in (.) do (set foldername=%%~nt)
	for %%t in (.) do (set finalfile=%%~nt.txt)
	set finalfile=%finalfile: =.%

::FiLETYPE: Set Variable
	if exist *.mkv (set filetype=mkv & goto found)
	if exist *.avi (set filetype=avi & goto found)
	if exist *.mp4 (set filetype=mp4 & goto found) else (goto nomovies)
	:found
	
::IMDB-URL-FILE-CHECK
	if exist url.txt (set /p imdb-url=<url.txt & cls & echo url.txt found & echo. & goto imdb-file-found)
	
::iMAGE-POSTER: Get From IMDB URL
	set /p imdb-url="IMDB URL: "
	
::iMAGE-POSTER: Get From url.txt
	:imdb-file-found
	echo Working on it. Sit tight.
	powershell -Command "(([uri]'%imdb-url%').Segments[-1]).Trim('/') | Out-File -encoding ASCII imdb.tmp"
	set /p imdb-id=<imdb.tmp
	powershell -Command "(Invoke-RestMethod -uri 'https://www.omdbapi.com/?i=%imdb-id%&apikey=e9498fb').Poster | Out-File img.tmp"
	powershell -Command "(gc img.tmp) -replace '300.jpg', '900.jpg' | Out-File -encoding ASCII posterimg.tmp"
	
::iMAGE-POSTER: Upload2Imgur
	set /p amazurl=<posterimg.tmp
	cli\shx\ShareX.exe "%amazurl%" -s -task "Upload2Imgur" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII imgurl.tmp"


:: -- BEGiN WRiTING TO NFO -- ::


::RELEASE TiTLE:
	(echo [center][size=3][b]%foldername%[/size][/b] & echo.)>> %finalfile%

::iMAGE-POSTER:
	set /p imgurl=<imgurl.tmp
	(echo [img]%imgurl%[/img] & echo.)>> %finalfile%

::iNFO TAG: Center Start, Size Start, Bold Start:
	(echo [info][/center][size=3][b] & echo.)>> %finalfile%

::RELEASE TiTLE:
	(echo RELEASE: %foldername% & echo.)>> %finalfile%
	
::EPiSODE COUNT:
	set count=0 & for %%z in (*.%filetype%) do set /a count+=1
	(echo EPiSODES: %count% & echo.)>> %finalfile%

::ViDEO BiTRATE: (Some MKV's don't have bitrate, so it pulls overall bitrate)
	if %filetype%==mkv (set mnfo=General) else (set mnfo=Video)
	for %%i in (*E01.*.%filetype%) do ((cli\mediainfo "--Output=%mnfo%;ViDEO: %%BitRate/String%%" "%%i") & echo.)>> %finalfile%

::ViDEO RESOLUTiON:
	for %%i in (*E01.*.%filetype%) do ((cli\mediainfo "--Output=Video;RESOLUTiON: %%Width%%x%%Height%%" "%%i") & echo.)>> %finalfile%

::AUDiO iNFO:
	for %%i in (*E01.*.%filetype%) do ((echo|set /p="AUDiO: " & cli\mediainfo cli\mediainfo "--Output=Audio;[%%BitRate/String%%, ][%%Format%%, ][%%Channel(s)/String%%]" "%%i") & echo.)>> %finalfile%

::LANGUAGE:
	(echo LANGUAGE: ENGLiSH & echo.)>> %finalfile%
	
::FiLETYPE
	for /f "usebackq delims=" %%I in (`powershell "\"%filetype%\".toUpper()"`) do set "filetypeup=%%~I"
	(echo FiLETYPE: %filetypeup% & echo.)>> %finalfile%

::ENCODER:
	(echo ENCODER: #EDITME & echo.)>> %finalfile%

::SOURCE:
	(echo SOURCE: #EDITME & echo.)>> %finalfile%

::NOTES:
	(echo NOTES: Enjoy. & echo.)>> %finalfile%

::iMDB URL
	(echo [center]https://www.imdb.com/title/%imdb-id%/ & echo.)>> %finalfile%

::PLOT TAG:
	(echo [plot] & echo.)>> %finalfile%

::PLOT:
	powershell -Command "(Invoke-RestMethod -uri 'https://www.omdbapi.com/?i=%imdb-id%&apikey=e9498fb').plot | Out-File plot.tmp"
	type plot.tmp >> %finalfile% & echo.>> %finalfile%

::SCREENS Head
	(echo [screens] & echo.)>> %finalfile%

::SCREENSHOTS-GENERATE
	for %%h in (*E01.*.%filetype%) do (
	cli\ffmpeg -skip_frame nokey -ss 00:03:00.00 -i "%%h" -frames:v 1 "01.png"
	cli\ffmpeg -skip_frame nokey -ss 00:06:00.00 -i "%%h" -frames:v 1 "02.png"
	cli\ffmpeg -skip_frame nokey -ss 00:07:00.00 -i "%%h" -frames:v 1 "03.png"
	)

::SCREENSHOTS-UPLOAD
	cls & echo Generating/Uploading Screenshots, this is slow
	cli\shx\ShareX.exe 01.png -s -task "UploadLocal" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII screen1.tmp"
	cli\shx\ShareX.exe 02.png -s -task "UploadLocal" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII screen2.tmp"
	cli\shx\ShareX.exe 03.png -s -task "UploadLocal" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII screen3.tmp"

::SCREENSHOTS-TO-NFO
	set /p scrntmp1=<screen1.tmp & set /p scrntmp2=<screen2.tmp & set /p scrntmp3=<screen3.tmp
	(echo [img]%scrntmp1%[/img] & echo.)>> %finalfile%
	(echo [img]%scrntmp2%[/img] & echo.)>> %finalfile%
	(echo [img]%scrntmp3%[/img] & echo.)>> %finalfile%


::RELEASE-GROUP: Banner
	echo [/size][/b][img]#EDITME[/img]>> %finalfile%

::RELEASE-GROUP: Footer
	echo [color=grey][i]#EDITME[/i][/color][/center] >> %finalfile%


:: -- END WRiTING TO NFO -- ::


::CLEANUP
	del /s /q "*.tmp"
	del /s /q "01.png" "02.png" "03.png"
	start notepad "%finalfile%"
	exit


	
::NO ViDEOS FOUND ERROR:
	:nomovies
	cls & echo no MP4, AVI or MKV found & pause & exit