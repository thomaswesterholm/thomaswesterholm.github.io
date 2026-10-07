@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo.
echo ==========================================
echo   Portfolio Git Sync
echo ==========================================
echo.

rem --- Basic checks ---
where git >nul 2>&1
if errorlevel 1 (
    echo ERROR: Git is not installed or not available in PATH.
    goto :fail
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
    echo ERROR: This folder is not a Git repository.
    goto :fail
)

rem --- Never continue through an unfinished merge/rebase ---
if exist ".git\rebase-merge" (
    echo ERROR: A Git rebase is already in progress.
    echo Resolve or abort it before running this script again.
    echo.
    git status
    goto :fail
)

if exist ".git\rebase-apply" (
    echo ERROR: A Git rebase is already in progress.
    echo Resolve or abort it before running this script again.
    echo.
    git status
    goto :fail
)

if exist ".git\MERGE_HEAD" (
    echo ERROR: A Git merge is already in progress.
    echo Resolve or abort it before running this script again.
    echo.
    git status
    goto :fail
)

rem --- Make sure we are on a normal branch ---
for /f "delims=" %%B in ('git branch --show-current') do set "BRANCH=%%B"

if not defined BRANCH (
    echo ERROR: Git is in detached HEAD state.
    echo No push will be attempted.
    echo.
    git status
    goto :fail
)

echo Branch: %BRANCH%
echo.

rem --- Safety check: do not commit unresolved conflict markers in HTML ---
findstr /S /M /C:"<<<<<<<" *.html >nul 2>&1
if not errorlevel 1 (
    echo ERROR: Unresolved Git conflict markers were found in an HTML file.
    echo Search for ^<^<^<^<^<^<^< before continuing.
    goto :fail
)

findstr /S /M /C:">>>>>>>" *.html >nul 2>&1
if not errorlevel 1 (
    echo ERROR: Unresolved Git conflict markers were found in an HTML file.
    echo Search for ^>^>^>^>^>^>^> before continuing.
    goto :fail
)

echo === Current status ===
git status
echo.
echo Review the changes above.
pause

rem --- Stage everything: new, modified, renamed and deleted files ---
git add -A
if errorlevel 1 (
    echo ERROR: git add failed.
    goto :fail
)

rem --- Commit only when staged changes exist ---
git diff --cached --quiet
if errorlevel 1 (
    echo.
    echo Creating local commit...
    git commit -m "Update portfolio"
    if errorlevel 1 (
        echo ERROR: Commit failed. Nothing will be pushed.
        goto :fail
    )
) else (
    echo.
    echo No local file changes to commit.
)

rem --- Fetch remote first, then replay local commits on top ---
echo.
echo Fetching latest changes from GitHub...
git fetch origin
if errorlevel 1 (
    echo ERROR: Could not fetch from GitHub.
    goto :fail
)

echo.
echo Rebasing local commits onto origin/%BRANCH%...
git rebase origin/%BRANCH%
if errorlevel 1 (
    echo.
    echo ==========================================
    echo   STOPPED: Rebase conflict detected
    echo ==========================================
    echo.
    echo Your local commit has NOT been discarded.
    echo Resolve the conflicted files, then run:
    echo.
    echo     git add -A
    echo     git rebase --continue
    echo.
    echo Or cancel the rebase with:
    echo.
    echo     git rebase --abort
    echo.
    echo Nothing has been pushed.
    goto :fail
)

rem --- Push only after a successful rebase ---
echo.
echo Pushing %BRANCH% to GitHub...
git push origin %BRANCH%
if errorlevel 1 (
    echo ERROR: Push failed.
    goto :fail
)

echo.
echo ==========================================
echo   DONE - local and GitHub are synchronized
echo ==========================================
echo.
git status
echo.
pause
exit /b 0

:fail
echo.
echo Script stopped without forcing any Git operation.
echo.
pause
exit /b 1
