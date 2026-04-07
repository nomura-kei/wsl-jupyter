# WSL Jpyter 環境

Jupyter 環境を構築します。

# インストール

プロキシ環境の場合は、
conf/proxy.txt にプロキシを設定してください。

install.bat を実行してください。

# 起動
start.bat を実行してください。
※install.bat 実行後は、起動している状態です。

# 利用方法
下記 URL にアクセスすることで、Jupyter を利用できます。

http://127.0.0.1:8000/lab?token=jupyter

外部からアクセスが必要な場合は、
install.bat の下記管理者権限の実行処理を有効にしてください。
```
    REM 管理者権限として本バッチを実行する。
REM    @powershell start-process %~0 -verb runas
```
↓
```
    REM 管理者権限として本バッチを実行する。
    @powershell start-process %~0 -verb runas
```



# アンインストール
uninstall.bat を実行ください。

