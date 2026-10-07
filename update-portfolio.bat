@echo off
cd /d "%~dp0"

echo.
echo === Git status ===
git status
echo.

pause

git add -A

git diff --cached --quiet
if %errorlevel%==0 (
    echo.
    echo Inga ändringar att committa.
    pause
    exit /b
)

git commit -m "Update portfolio"
git push

echo.
echo Klar.
pause