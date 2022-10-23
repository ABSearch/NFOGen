	@echo off

::CLEANUP1: (Delete tmp dir)
	if exist "cli\tmpdir" RMDIR /s /q cli\tmpdir

::SET FOLDER/FiLE Names (To the current foldername) (final line replaces spaces with periods)
	for %%t in (.) do (set foldername=%%~nt)
	for %%t in (.) do (set finalfile=%%~nt.txt)
	set finalfile=%finalfile: =.%

::FiLETYPE: Set Variable
	if exist *.mkv (set filetype=mkv & goto found)
	if exist *.avi (set filetype=avi & goto found)
	if exist *.mp4 (set filetype=mp4 & goto found) else (goto nomovies)
	:found
	
::SET TEMP DIR
	if not exist "cli\tmpdir" mkdir "cli\tmpdir" & set tmp=cli\tmpdir

::SET EPiSODE 01
	for %%i in (*E01*.%filetype%) do (set ep01=%%i)
	
::SET SCREENSHOT TIMES: Based on length
	(cli\mediainfo "--Output=General;%%Duration%%" "%ep01%")>%tmp%\dur.tmp
	(set /p durr=<%tmp%\dur.tmp)
	(set /a t1 = %durr%/1000/4*1)&(set /a t2 = %durr%/1000/4*2)&(set /a t3 = %durr%/1000/4*3)
	
::IMDB-URL-FILE-CHECK
	if exist url.txt (set /p imdb-url=<url.txt & cls & echo url.txt found & echo. & goto imdb-file-found)
	
::iMAGE-POSTER: Get From IMDB URL
	set /p imdb-url="IMDB URL: "
	
::iMAGE-POSTER: Get From url.txt
	:imdb-file-found
	echo Working on it. Sit tight.
	for /f "delims=" %%i in ('powershell -Command "(([uri]'%imdb-url%').Segments[-1]).Trim('/')"') DO SET "imdb-id=%%i"
	powershell -Command "(Invoke-RestMethod -uri 'https://www.omdbapi.com/?i=%imdb-id%&apikey=e9498fb').Poster | Out-File %tmp%\img.tmp"
	powershell -Command "(gc %tmp%\img.tmp) -replace '300.jpg', '900.jpg' | Out-File -encoding ASCII %tmp%\posterimg.tmp"
	
::iMAGE-POSTER: Upload2Imgur
	set /p amazurl=<%tmp%\posterimg.tmp
	cli\shx\ShareX.exe "%amazurl%" -s -task "Upload2Imgur" -autoclose
	for /f "delims=" %%i in ('powershell -Command "Get-Clipboard"') DO SET "imgurl=%%i"


:: -- BEGiN WRiTING TO NFO -- ::


::RELEASE TiTLE:
	(echo [center][size=3][b]%foldername%[/size][/b] & echo.)>> %finalfile%

::iMAGE-POSTER:
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
	(cli\mediainfo "--Output=%mnfo%;ViDEO: %%BitRate/String%%" "%ep01%" & echo.)>> %finalfile%

::ViDEO RESOLUTiON:
	(cli\mediainfo "--Output=Video;RESOLUTiON: %%Width%%x%%Height%%" "%ep01%" & echo.)>> %finalfile%

::AUDiO iNFO:
	(echo|set /p="AUDiO: " & cli\mediainfo cli\mediainfo "--Output=Audio;[%%BitRate/String%%, ][%%Format%%, ][%%Channel(s)/String%%]" "%ep01%" & echo.)>> %finalfile%

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
	powershell -Command "(Invoke-RestMethod -uri 'https://www.omdbapi.com/?i=%imdb-id%&apikey=e9498fb').plot | Out-File %tmp%\plot.tmp"
	type %tmp%\plot.tmp >> %finalfile% & echo.>> %finalfile%

::SCREENS Head
	(echo [screens] & echo.)>> %finalfile%

::SCREENSHOTS-GENERATE
	cli\ffmpeg -skip_frame nokey -ss %t1%.00 -i "%ep01%" -frames:v 1 "%tmp%\01.png"
	cli\ffmpeg -skip_frame nokey -ss %t2%.00 -i "%ep01%" -frames:v 1 "%tmp%\02.png"
	cli\ffmpeg -skip_frame nokey -ss %t3%.00 -i "%ep01%" -frames:v 1 "%tmp%\03.png"

::SCREENSHOTS-CHECK
	if not exist %tmp%\03.png (goto noscreens)

::SCREENSHOTS-UPLOAD
	cls & echo Uploading Screenshots, this is slow
	cli\shx\ShareX.exe %tmp%\01.png -s -task "UploadLocal" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII %tmp%\screen1.tmp"
	cli\shx\ShareX.exe %tmp%\02.png -s -task "UploadLocal" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII %tmp%\screen2.tmp"
	cli\shx\ShareX.exe %tmp%\03.png -s -task "UploadLocal" -autoclose
	powershell -Command "Get-Clipboard | Out-File -encoding ASCII %tmp%\screen3.tmp"

::SCREENSHOTS-TO-NFO
	set /p scrntmp1=<%tmp%\screen1.tmp & set /p scrntmp2=<%tmp%\screen2.tmp & set /p scrntmp3=<%tmp%\screen3.tmp
	(echo [img]%scrntmp1%[/img] & echo.)>> %finalfile%
	(echo [img]%scrntmp2%[/img] & echo.)>> %finalfile%
	(echo [img]%scrntmp3%[/img] & echo.)>> %finalfile%


::RELEASE-GROUP: Banner
	echo [/size][/b][img]#EDITME[/img]>> %finalfile%

::RELEASE-GROUP: Footer
	echo [color=grey][i]#EDITME[/i][/color][/center] >> %finalfile%


:: -- END WRiTING TO NFO -- ::


::CLEANUP2: (Delete tmp dir)
	if exist "cli\tmpdir" RMDIR /s /q cli\tmpdir
	start notepad "%finalfile%"
	exit


	
::ERRORs:
	:nomovies
	cls & echo no MP4, AVI or MKV found & pause & exit
	
	:noscreens
	cls & echo One or more screenshots are missing & pause & exit
