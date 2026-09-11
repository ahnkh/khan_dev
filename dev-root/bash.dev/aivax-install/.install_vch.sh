
g_path=$( cd "$(dirname "$0")" ; pwd )

function WRITE_LOG()
{

    GREEN='\033[1;32m'
    NC='\033[0m'

    bold=$(tput bold)
    normal=$(tput sgr0)

    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo -e "${GREEN}[$(date '+%Y/%m/%d %H:%M:%S')]${NC}${bold} $3 ${normal}"
    
}

function __install_opensearch_config()
{
    WRITE_LOG $FUNCNAME $LINENO "install opensearch config"

    rm -rf /tmp/install-temp/opensearch-config

    mkdir -p /tmp/install-temp/opensearch-config
    tar xzf ./data-setup/opensearch-setup/opensearch.config.tar.gz  -C /tmp/install-temp/opensearch-config

    if [ -d /etc/opensearch.old ]
    then
        mv /etc/opensearch.old /etc/opensearch.old.$(date +%Y%m%d%H%M)
    fi

    if [ -d /etc/opensearch ]
    then
        \mv /etc/opensearch /etc/opensearch.old
    fi

    \mv /tmp/install-temp/opensearch-config/opensearch /etc/

    chown -R opensearch:opensearch /etc/opensearch
    chmod -R 750 /etc/opensearch

    NEW_PATH="/data/opensearch"
    CONFIG_FILE="/etc/opensearch/opensearch.yml"

    sudo sed -i "s|path.data:.*|path.data: $NEW_PATH|g" "$CONFIG_FILE"

    if grep -q '^vm.max_map_count=' /etc/sysctl.conf; then
        sed -i 's/^vm.max_map_count=.*/vm.max_map_count=262144/' /etc/sysctl.conf
    else
        echo 'vm.max_map_count=262144' >> /etc/sysctl.conf
    fi

    cat > /etc/systemd/system/opensearch.service <<'EOF'
[Unit]
Description=OpenSearch
Documentation=https://opensearch.org/
Wants=network-online.target
After=network-online.target

[Service]
Type=notify
RuntimeDirectory=opensearch
PrivateTmp=true
EnvironmentFile=-/etc/default/opensearch
EnvironmentFile=-/etc/sysconfig/opensearch
User=opensearch
Group=opensearch

#WorkingDirectory=/data/aivax/data_resource/opensearch
WorkingDirectory=/data/opensearch

ExecStartPre=/bin/mkdir -p /dev/shm/performanceanalyzer
ExecStartPre=/bin/chown opensearch:opensearch /dev/shm/performanceanalyzer

ExecStart=/usr/share/opensearch/bin/systemd-entrypoint -p ${PID_DIR}/opensearch.pid --quiet

StandardOutput=journal
StandardError=inherit
SyslogIdentifier=opensearch

LimitNOFILE=65535
LimitNPROC=4096
LimitAS=infinity
LimitFSIZE=infinity

TimeoutStopSec=0
KillSignal=SIGTERM
KillMode=process
SendSIGKILL=no
SuccessExitStatus=143

TimeoutStartSec=75

PrivateTmp=true
ProtectSystem=full
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
ProtectProc=invisible
RestrictNamespaces=true
LockPersonality=true
NoNewPrivileges=true
RestrictSUIDSGID=true
RestrictRealtime=true
ProtectHostname=true
ProtectKernelLogs=true
ProtectClock=true

CapabilityBoundingSet=~CAP_SYS_ADMIN ~CAP_SYS_PTRACE ~CAP_NET_ADMIN ~CAP_BLOCK_SUSPEND ~CAP_LEASE ~CAP_SYS_PACCT ~CAP_SYS_TTY_CONFIG

SystemCallArchitectures=native
SystemCallFilter=seccomp mincore
SystemCallFilter=madvise mlock mlock2 munlock get_mempolicy sched_getaffinity sched_setaffinity fcntl
SystemCallFilter=@system-service
SystemCallFilter=~@reboot
SystemCallFilter=~@swap
SystemCallErrorNumber=EPERM

RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

ReadWritePaths=/data/opensearch
ReadWritePaths=/dev/shm
ReadWritePaths=-/etc/opensearch
ReadWritePaths=-/mnt/snapshots

#ReadOnlyPaths=-/etc/os-release -/usr/lib/os-release -/etc/system-release
#ReadOnlyPaths=/proc/self/mountinfo /proc/diskstats
#ReadOnlyPaths=/proc/self/cgroup
#ReadOnlyPaths=/sys/fs/cgroup

ReadOnlyPaths=/proc/self/cgroup /sys/fs/cgroup/cpu /sys/fs/cgroup/cpu/-
ReadOnlyPaths=/sys/fs/cgroup/cpuacct /sys/fs/cgroup/cpuacct/- /sys/fs/cgroup/memory /sys/fs/cgroup/memory/-
ReadOnlyPaths=/sys/fs/cgroup/system.slice/-

RestrictNamespaces=true

NoNewPrivileges=true

# Memory and execution protection

# Allow only native system calls
SystemCallArchitectures=native
# Service does not share key material with other services
KeyringMode=private
# Prevent changing ABI personality
LockPersonality=true
# Prevent creating SUID/SGID files
RestrictSUIDSGID=true
# Prevent acquiring realtime scheduling
RestrictRealtime=true
# Prevent changes to system hostname
ProtectHostname=true
# Prevent reading/writing kernel logs
ProtectKernelLogs=true
# Prevent tampering with the system clock
ProtectClock=true

[Install]
WantedBy=multi-user.target
EOF
}

function __install_opensearch_data()
{
    WRITE_LOG $FUNCNAME $LINENO "install opensearch data"

    rm -rf /tmp/install-temp/opensearch-data

    if [ -d /data/opensearch ]
    then

        WRITE_LOG $FUNCNAME $LINENO "opensearch is already installed, stop install"
        return
    fi

    mkdir -p /tmp/install-temp/opensearch-data
    tar xzf ./data-setup/opensearch-setup/opensearch.data.tar.gz -C /tmp/install-temp/opensearch-data/

    mv /tmp/install-temp/opensearch-data/opensearch_docker /tmp/install-temp/opensearch-data/opensearch

    mv /tmp/install-temp/opensearch-data/opensearch /data/

    chown -R opensearch:opensearch /data/opensearch
    chmod -R 750 /data/opensearch
}

function __install_opensearch()
{
    WRITE_LOG $FUNCNAME $LINENO "install opensearch"

    dnf install ./extension/rpm-install/3rd-repo/opensearch/v3.3.2/opensearch-3.3.2-linux-x64.rpm -y -q

    __install_opensearch_config

    __install_opensearch_data
    

    # WRITE_LOG $FUNCNAME $LINENO "finish install opensearch"
}


function __setup_aivax_venv()
{

    WRITE_LOG $FUNCNAME $LINENO "setup aivax venv"
    
    mkdir -p /home1/aivax
    
    VENV="/home1/aivax/aivax-venv"

    if [ ! -d "$VENV" ]; then

        /usr/local/bin/uv venv --python /usr/local/bin/python3.13 "$VENV"
        \cp -rf /usr/local/bin/uv ${VENV}/bin/
    fi

    source /home1/aivax/aivax-venv/bin/activate

    python -m ensurepip --default-pip

    FILE="/root/.bash_profile"

    if ! grep -q "# >>> AIVAX VENV >>>" "$FILE"; then
cat << 'EOF' >> "$FILE"

# >>> AIVAX VENV >>>
source /home1/aivax/aivax-venv/bin/activate
# <<< AIVAX VENV <<<
EOF
fi

    cd ./extension/python-install

    uv --quiet pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt

    uv --quiet pip install ./offline-wheel/pycomlib-1.1.7-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pycomlibex-1.1.2-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pyservice-1.0.3-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pytoolkit-1.0.0-py3-none-any.whl --force-reinstall

    cd - > /dev/null 2>&1

}



function main()
{
    __install_opensearch

    __setup_aivax_venv
}

main $@