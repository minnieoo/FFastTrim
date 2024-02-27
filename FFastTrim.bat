@echo off
setlocal enabledelayedexpansion

:: where sped up videos output to
set "outputFolder=%userprofile%\Downloads"


:: ask the user for their video, if it doesn't exist, ask again
:process_video
set /p "inputPath=Enter the path of the input video file: "
if not exist "%inputPath%" (
    echo Input video file does not exist. Try again.
    goto :process_video
)



:: use ffmpeg to get the duration of the video
for /f "delims=" %%I in ('ffmpeg -i "%inputPath%" 2^>^&1 ^| findstr "Duration"') do set duration=%%I

:: extract and format the duration string
set duration=%duration:*Duration=%
set duration=%duration:~1,11%

:: remove milliseconds from duration, duration now in hh:mm:ss format
for /f "tokens=1 delims=." %%a in ("%duration%") do set duration=%%a
echo Duration of the video is: %duration% 

:: convert duration to total seconds
for /f "tokens=1-3 delims=:" %%a in ("%duration%") do (
    set /a totalSeconds=%%a*3600 + %%b*60 + %%c
)

:: ask for speed factor
set /p "speed=Enter the speed factor (ex: 0.5 = 2x as fast): "

:: use powershell to calculate the new duration by multiplying the total seconds of the video by the speed factor
echo DURATION %duration% and SPEED %speed%
for /f %%i in ('powershell -Command %totalSeconds% * %speed%') do set newDuration=%%i
echo "NEW DURATION = !newDuration!"


:: calculate hours, minutes, and seconds
set /a hours=newDuration / 3600
set /a minutes=(newDuration %% 3600) / 60
set /a seconds=newDuration %% 60

:: format to HH:MM:SS for trimming
if !hours! lss 10 set hours=0!hours!
if !minutes! lss 10 set minutes=0!minutes!
if !seconds! lss 10 set seconds=0!seconds!
set "f_Duration=!hours!:!minutes!:!seconds!"

:: speed the video up with ffmpeg using their chosen speed, outputing to download folder
echo "FORMATTED DURATION IS !f_duration!"
set "outputFileName=%random%_!speed!.mp4"
ffmpeg -i "!inputPath!" -ss 00:00:00 -to !f_Duration! -filter_complex "[0:v]setpts=!speed!*PTS[v];[0:a]atempo=1/!speed![a]" -map "[v]" -map "[a]" "!outputFolder!\!outputFileName!"


:: show user output
if not exist "!outputFolder!\!outputFileName!" (
    echo An error occured! Try again.
    goto :process_video
)

echo [42mVideo processing complete. Output file: "!outputFolder!\!outputFileName!"
echo Speed Factor: %speed%
echo Old Duration: %duration%
echo Current Duration: %f_Duration% [0m
goto :final



:: ask if the user wants to process another video
:final
set /p "continue=Do you want to process another video? (Y/N): "
if /i "%continue%" equ "Y" goto :process_video
if /i "%continue%" equ "N" exit
echo Invalid input. Try again with either Y or N.
goto :final


pause
