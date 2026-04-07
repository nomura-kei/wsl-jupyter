@echo off
rem プロキシサーバーを構築します。
cd %~dp0

setlocal enabledelayedexpansion

rem ALPINE のイメージURL
set ALPINE_IMAGE_URL=https://dl-cdn.alpinelinux.org/alpine/v3.23/releases/x86_64/alpine-minirootfs-3.23.3-x86_64.tar.gz

net session >NUL 2> NUL
if %ERRORLEVEL% neq 0 (
rem ===== 管理者権限でない場合の処理 =====

    rem images に Alpine のイメージがなければダウンロードする。
    if exist  %~dp0images\alpine-minirootfs*.tar.gz (
        echo image downloaded
    ) else (
        mkdir images
        curl -fSsL -k -o images\alpine-minirootfs-x.x.x-x86_64.tar.gz %ALPINE_IMAGE_URL%
    )

    rem Alpine を WSL へインストールする。
    echo Install WslJupyter
    wsl --import WslJupyter %LOCALAPPDATA%\Packages\WslJupyter images\alpine-minirootfs-x.x.x-x86_64.tar.gz

    rem WSL 上ファイルパス設定
    set "WIN_BASE_PATH=%~dp0"
    set "WIN_BASE_PATH=!WIN_BASE_PATH:~0,-1!"
    for /F "usebackq delims=" %%p in (`wsl -d WslJupyter wslpath -a -u "!WIN_BASE_PATH!"`) do set "WIN_BASE_PATH=%%p"

    rem install.sh を実行
    wsl -d WslJupyter -u root --exec /bin/cp -f "!WIN_BASE_PATH!/scripts/install.sh" /tmp/
    wsl -d WslJupyter -u root --exec /bin/sh /tmp/install.sh "!WIN_BASE_PATH!" install
    if errorlevel 1 (
        exit /b 1
    )

    REM 管理者権限として本バッチを実行する。
REM    @powershell start-process %~0 -verb runas
    goto:eof
)

REM ===== 管理者権限の場合の処理 =====
REM portproxy で 外部から WslJupyter の 8000 へアクセスできるようにする。
set /P WSL_ADDRESS=<"%~dp0conf\wsl_address.txt"
netsh interface portproxy set v4tov4 listenport=8000 connectport=8000 listenaddress=0.0.0.0 connectaddress=%WSL_ADDRESS%

endlocal
