#!/bin/sh
WIN_BASE_PATH=$1

# ----------------------------------------------------------------------
#  save wsl ipaddress (conf/wsl_address.txt)
# ----------------------------------------------------------------------
save_wsl_ipaddress() {
    IPADDRESS=`ip -4 addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1`
    echo "${IPADDRESS}" > "${WIN_BASE_PATH}/conf/wsl_address.txt"
}

# ----------------------------------------------------------------------
#  add jupyter user
# ----------------------------------------------------------------------
add_jupyter_user() {
    [ ! -d /opt/jupyter ] && adduser -D -h /opt/jupyter jupyter
    PROFILE=/opt/jupyter/.profile
    grep '#@ uv settings' ${PROFILE}
    if [ $? -ne 0 ]; then
        echo '#@ uv settings' >> ${PROFILE}
        echo 'export PATH=${PATH}:~/.local/bin' >> ${PROFILE}
        echo "export http_proxy=${http_proxy}" >> ${PROFILE}
        echo "export https_proxy=${https_proxy}" >> ${PROFILE}
    fi
}

# ----------------------------------------------------------------------
#  install python (uv, openrc, sudo, bash, git, curl, shadow install)
# ----------------------------------------------------------------------
install_python() {
    # install uv
    which uv
    if [ $? -ne 0 ]; then
        apk update && apk add --no-cache uv openrc sudo bash git curl shadow
    fi

    # install python
    su - jupyter << 'EOF'
PYTHON_LIST=$(uv python list --only-installed)
if [ "${PYTHON_LIST}" = "" ]; then
    uv python install
fi
EOF
}

# ----------------------------------------------------------------------
#  install jupyter
# ----------------------------------------------------------------------
install_jupyter() {
    if [ -d /opt/jupyter/wsl-jupyter ]; then
        return 0
    fi
    su - jupyter << 'EOF'
mkdir -p /opt/jupyter/wsl-jupyter
cd /opt/jupyter/wsl-jupyter
uv init
uv add jupyter
EOF
    return 0
}

# ----------------------------------------------------------------------
#  configure the network
# ----------------------------------------------------------------------
configure_network() {
    if [ ! -f /etc/network/interfaces ]; then
        echo "Configure the network"
        /bin/cp "${WIN_BASE_PATH}/conf/interfaces" /etc/network/
    fi
}

# ----------------------------------------------------------------------
#  configure the jupyter
# ----------------------------------------------------------------------
configure_jupyter() {
    if [ -d /opt/jupyter/wsl-jupyter/notebook ]; then
        return 0
    fi
    su - jupyter << 'EOF'
    if [ -f ~/.jupyter/jupyter_lab_config.py ]; then
        return 0
    fi
cd /opt/jupyter/wsl-jupyter
uv run jupyter lab --generate-config
sed -i \
    -e "s/^# c.ServerApp.ip.*$/c.ServerApp.ip = '0.0.0.0'/" \
    -e "s/^# c.ServerApp.port.*$/c.ServerApp.port = 8000/"  \
    -e "s/^# c.ServerApp.password_required.*$/c.ServerApp.password_required = False/" \
    -e "s/^# c.ServerApp.token.*$/c.ServerApp.token = 'jupyter'/" \
    -e "s/^# c.ServerApp.notebook_dir.*$/c.ServerApp.notebook_dir = '\/opt\/jupyter\/wsl-jupyter\/notebook'/" \
    -e "s/^# c.ExtensionApp.open_browser.*$/c.ExtensionApp.open_browser = False/" \
    ~/.jupyter/jupyter_lab_config.py
mkdir -p /opt/jupyter/wsl-jupyter/notebook
EOF
    /bin/cp -rf "${WIN_BASE_PATH}/notebook/"* /opt/jupyter/wsl-jupyter/notebook/
    /bin/chown -R jupyter:jupyter /opt/jupyter/wsl-jupyter/notebook
    /bin/cp -f "${WIN_BASE_PATH}/conf/jupyter" /etc/init.d/
    /bin/chmod +x /etc/init.d/jupyter
    /sbin/rc-update add jupyter default
    return 0
}

# ----------------------------------------------------------------------
#  configure the others
# ----------------------------------------------------------------------
configure_others() {
    # sudo settings
    if [ ! -f /etc/sudoers.d/wheel ]; then
        echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
        gpasswd -a jupyter wheel
    fi

    # System32 Path Settings
    su - jupyter << 'EOF'
    grep '#@ System32 path settings' ~/.profile
    if [ $? -ne 0 ]; then
        echo '#@ System32 path settings' >> ~/.profile
        WSL_COMMAND=$(ls /mnt/*/WINDOWS/System32/wsl.exe)
        if [ "${WSL_COMMAND}" != "" ]; then
            SYSTEM32_PATH=$(dirname ${WSL_COMMAND})
            echo 'export PATH=${PATH}:'"${SYSTEM32_PATH}" >> ~/.profile
        fi
    fi
EOF
}

# ----------------------------------------------------------------------
#  create jupyter config
# ----------------------------------------------------------------------
create_jupyter_config() {
    grep export /opt/jupyter/.profile > /etc/conf.d/jupyter
}


# プロキシ設定
[ -f "${WIN_BASE_PATH}/conf/proxy.txt" ] && . "${WIN_BASE_PATH}/conf/proxy.txt"

save_wsl_ipaddress
add_jupyter_user
install_python
install_jupyter
configure_network
configure_jupyter
configure_others
create_jupyter_config
if [ $? -eq 0 ]; then
    openrc default
fi
