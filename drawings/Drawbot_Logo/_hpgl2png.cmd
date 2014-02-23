@echo off

set CONVERT="C:\Program Files (x86)\ImageMagick-6.8.4-Q16\convert.exe"

echo Generating preview thumbnails...

FOR %%b in (*.hpgl) do %CONVERT% "%%b" -resize 1000 -background white -flatten -threshold "99%%" -flip "%%~nb_tn.png"

REM pause
