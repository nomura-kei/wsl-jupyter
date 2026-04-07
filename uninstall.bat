@echo off
net session >NUL 2> NUL
if %ERRORLEVEL% neq 0 (
    rem ===== 管理者権限でない場合の処理 =====
    wsl --terminate WslJupyter
    wsl --unregister WslJupyter
    REM 管理者権限として本バッチを実行する。
REM    @powershell start-process %~0 -verb runas
    goto:eof
)

REM ===== 管理者権限の場合の処理 =====
REM 不要となったポート設定を削除する。
netsh interface portproxy delete v4tov4 listenport=8000 listenaddress=0.0.0.0 
