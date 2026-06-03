@echo off
setlocal enabledelayedexpansion

echo ========================================
echo Environment of Coral iSEM10 v2
echo ========================================
echo.

:: Ensure we are in the repository root
for /f "delims=" %%R in ('git rev-parse --show-toplevel 2^>nul') do set "repo_root=%%R"
if not defined repo_root (
    echo ERROR: not a git repository.
    exit /b 1
)
cd /d "%repo_root%"

:: Checkout master and pull the main repo with submodules
call git checkout master
if errorlevel 1 exit /b 1
call git pull --recurse-submodules
if errorlevel 1 exit /b 1

:: Initial submodule sync/update
call git submodule sync --recursive
call git submodule update --init --recursive || echo.

:: Parse .gitmodules and update each referenced path
if exist .gitmodules (
    echo.
    echo Syncing submodules from .gitmodules
    for /f "usebackq tokens=1* delims= " %%A in (`git config -f .gitmodules --get-regexp "^submodule\..*\.path$"`) do (
        set "key=%%A"
        set "path=%%B"
        set "module=!key:submodule.=!"
        set "module=!module:.path=!"
        for /f "delims=" %%U in ('git config -f .gitmodules "submodule.!module!.url" 2^>nul') do set "url=%%U"
        for /f "delims=" %%B in ('git config -f .gitmodules "submodule.!module!.branch" 2^>nul') do set "branch=%%B"

        if not defined url (
            echo -- Skipping !path!: missing url in .gitmodules
        ) else (
            set "path_has_git=false"
            if exist "!path!\.git" set "path_has_git=true"

            if not exist "!path!" (
                echo -- Cloning missing submodule !path!
                if defined branch (
                    call git clone --branch "!branch!" --single-branch "!url!" "!path!"
                ) else (
                    call git clone "!url!" "!path!"
                )
                if errorlevel 1 exit /b 1
            ) else if "%path_has_git%" == "false" (
                echo -- Removing invalid or empty path !path!
                rd /s /q "!path!"
                if defined branch (
                    call git clone --branch "!branch!" --single-branch "!url!" "!path!"
                ) else (
                    call git clone "!url!" "!path!"
                )
                if errorlevel 1 exit /b 1
            ) else (
                set "folder_has_files="
                for /f "delims=" %%F in ('dir /b "!path!" 2^>nul') do set "folder_has_files=true"
                if not defined folder_has_files (
                    echo -- Removing invalid or empty path !path!
                    rd /s /q "!path!"
                    if defined branch (
                        call git clone --branch "!branch!" --single-branch "!url!" "!path!"
                    ) else (
                        call git clone "!url!" "!path!"
                    )
                    if errorlevel 1 exit /b 1
                )
            )

            if exist "!path!\.git" (
                echo -- Updating submodule !path!
                call git -C "!path!" remote set-url origin "!url!"
                call git -C "!path!" fetch origin --prune
                if defined branch (
                    call git -C "!path!" rev-parse --verify --quiet "refs/heads/!branch!" >nul 2>nul
                    if errorlevel 1 (
                        call git -C "!path!" rev-parse --verify --quiet "refs/remotes/origin/!branch!" >nul 2>nul
                        if errorlevel 1 (
                            echo WARNING: branch "!branch!" not found locally or on origin for !path!
                        ) else (
                            call git -C "!path!" checkout -B "!branch!" "origin/!branch!"
                        )
                    ) else (
                        call git -C "!path!" checkout "!branch!"
                    )
                    call git -C "!path!" branch --set-upstream-to="origin/!branch!" "!branch!"
                    call git -C "!path!" pull --ff-only origin "!branch!"
                    if errorlevel 1 exit /b 1
                    for /f "delims=" %%R in ('git -C "!path!" rev-parse HEAD') do set "local_rev=%%R"
                    for /f "delims=" %%R in ('git -C "!path!" rev-parse "origin/!branch!"') do set "remote_rev=%%R"
                    if not "!local_rev!"=="!remote_rev!" (
                        echo ERROR: !path! HEAD (!local_rev!) does not match origin/!branch! (!remote_rev!)
                        exit /b 1
                    )
                ) else (
                    call git -C "!path!" pull --ff-only
                    if errorlevel 1 exit /b 1
                )
                if not exist "!path!\*" (
                    echo ERROR: !path! is empty after pull
                    exit /b 1
                )
            )
        )
        set "url="
        set "branch="
        set "local_rev="
        set "remote_rev="
    )
)

:: Final sync and verify
call git submodule sync --recursive
call git submodule update --init --recursive --force || echo.

for /f "delims=" %%S in ('git submodule --quiet foreach --recursive "if [ -z \"\$(ls -A . 2>/dev/null)\" ]; then echo EMPTY: \$sm_path; fi" 2^>nul') do (
    echo %%S
    if /i "%%S"=="EMPTY:" exit /b 1
)

endlocal
exit /b 0
