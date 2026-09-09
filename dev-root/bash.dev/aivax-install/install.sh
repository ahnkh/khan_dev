g_path=$( cd "$(dirname "$0")" ; pwd )

TRACE_LOG="./trace-log"

function WRITE_LOG()
{

    GREEN='\033[1;32m'
    NC='\033[0m'

    bold=$(tput bold)
    normal=$(tput sgr0)

    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo -e "${GREEN}[$(date '+%Y/%m/%d %H:%M:%S')]${NC}${bold} $3 ${normal}"
    
    echo $string &>> ${g_path}/${TRACE_LOG}
}

function WRITE_ERROR()
{

    RED='\033[0;31m'    
    NC='\033[0m'

    bold=$(tput bold)
    normal=$(tput sgr0)
    
    echo -e "${RED}${bold}[$(date '+%Y/%m/%d %H:%M:%S')] $3 ${normal} ${NC} "
    
    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo $string &>> ${g_path}/${log_file}
}


# 최초 기본 rpm 모듈 설치
function install_default_modules()
{
    rpm -ih --quiet ./extension/rpm-install/extra-repo/dialog/dialog-1.3-32.20210117.el9.0.1.x86_64.rpm > /dev/null 2>&1

    __install_python

}

# 기본 설정 추가
function init_default_setup()
{

    WRITE_LOG $FUNCNAME $LINENO "start init default setup"
    
    mkdir -p /home1/aivax.old

    TODAY=$(date +%Y%m%d)

    if [ -d /home1/aivax.old/aivax.$TODAY ]
    then
        mv /home1/aivax.old/aivax.$TODAY /home1/aivax.old/aivax.$(date +%Y%m%d%H%M)
    fi

    if [ -d /home1/aivax ] 
    then
        mv /home1/aivax /home1/aivax.old/aivax.$TODAY
    fi

    mkdir -p /home1/aivax/
    mkdir -p /home1/aivax/extension

    mkdir -p /home1/aivax/data_resource && rm -rf /home1/aivax/data_resources
    mkdir -p /home1/aivax/data_resource/attach_file

    mkdir -p /home1/aivax/data_resource/policy_signal

    mkdir -p /home1/install/extension/rpm-repo/

    \cp -rf ./data-setup/etc-resource/aivax_policy.json /home1/aivax/data_resource/policy_signal/
    \cp -rf ./data-setup/etc-resource/block.html /home1/aivax/data_resource/

    mkdir -p /data/backup/opensearch_snapshot
    chown -hR opensearch:opensearch /data/backup/opensearch_snapshot
    chmod 750 /data/backup/opensearch_snapshot

    mkdir -p /data/backup/attach_file_backup
    mkdir -p /data/backup/prompt_log_backup

    setenforce 0

    chmod 755 /usr/bin/dnf

    sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

    WRITE_LOG $FUNCNAME $LINENO "finish init default setup"
}

function install_module()
{

    WRITE_LOG $FUNCNAME $LINENO "start install module"
    __install_rpm_repo

    __istall_rpm_package

    __install_fluentbit

    __install_mariadb

    __install_nginx

    __install_nodejs

    __install_squid

    __install_opensearch

    __install_slm

    WRITE_LOG $FUNCNAME $LINENO "finish install module"
}

function __install_rpm_repo()
{
    WRITE_LOG $FUNCNAME $LINENO "start install rpm repo"

    mkdir -p /etc/yum.repos.d_bak
    mkdir -p /etc/yum.repos.d

    \cp -rf /etc/yum.repos.d/* /etc/yum.repos.d_bak/

    rm -rf /etc/yum.repos.d/*.repo

    \cp -f ./extension/rpm-install/aivax.repo /etc/yum.repos.d/

    mkdir -p /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/base-repo/*.rpm /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/extra-repo/libreoffice-full/*.rpm /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/extra-repo/tesseract/*.rpm /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/extra-repo/nginx/v1.30/*.rpm /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/extra-repo/perl/*.rpm /home1/install/extension/rpm-repo/
    \cp -f ./extension/rpm-install/extra-repo/mariadb/v11.3.2/*.rpm /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/extra-repo/zip/*.rpm /home1/install/extension/rpm-repo/

    \cp -f ./extension/rpm-install/extra-repo/squid_proxy/*.rpm /home1/install/extension/rpm-repo/


    rpm -ih --quiet ./extension/rpm-install/createrepo/createrepo_c-libs-0.20.1-4.el9.x86_64.rpm > /dev/null
    rpm -ih --quiet ./extension/rpm-install/createrepo/createrepo_c-0.20.1-4.el9.x86_64.rpm > /dev/null

    createrepo /home1/install/extension/rpm-repo/

    dnf clean all
    dnf makecache

    WRITE_LOG $FUNCNAME $LINENO "finish install rpm package"

}

function __istall_rpm_package()
{
    WRITE_LOG $FUNCNAME $LINENO "start install rpm package"

    dnf install jq --disablerepo="*" --enablerepo="aivax-repo" -y -q

    dnf install libreoffice* --disablerepo="*" --enablerepo="aivax-repo" -y -q

    dnf install tesseract --disablerepo="*" --enablerepo="aivax-repo" -y -q 

    dnf install tesseract-langpack-kor --disablerepo="*" --enablerepo="aivax-repo" -y -q 

    dnf install MariaDB-server MariaDB-client --disablerepo="*" --enablerepo="aivax-repo" -y -q

    dnf install libpcap --disablerepo="*" --enablerepo="aivax-repo" -y -q

    dnf install --disablerepo="*" --enablerepo="aivax-repo" MariaDB-server MariaDB-client -y -q 

    dnf remove nginx nginx-core nginx-filesystem -y -q

    dnf install --disablerepo="*" --enablerepo="aivax-repo" nginx -y -q

    dnf install --disablerepo="*" --enablerepo="aivax-repo" zip -y -q
    dnf install --disablerepo="*" --enablerepo="aivax-repo" unzip -y -q

    dnf install --disablerepo="*" --enablerepo="aivax-repo" squid -y -q

    dnf install --disablerepo="*" --enablerepo="aivax-repo" cmake -y -q

    WRITE_LOG $FUNCNAME $LINENO "finish install rpm package"
}

function __install_fluentbit()
{
    WRITE_LOG $FUNCNAME $LINENO "start install fluent-bit"

    cp -rf ./extension/fluent-bit /home1/aivax/

    mkdir -p /home1/aivax/fluent-bit/db
    mkdir -p /home1/aivax/fluent-bit/trace_log

    cp -rf ./extension/fluent-bit/fluent-bit.service /etc/systemd/system/

    chmod 755 /home1/aivax/fluent-bit/fluent-bit
    
    systemctl daemon-reload
    systemctl enable fluent-bit.service
    systemctl start fluent-bit

    WRITE_LOG $FUNCNAME $LINENO "finish install fluent-bit"
}

function __install_mariadb()
{
    WRITE_LOG $FUNCNAME $LINENO "start install mariadb"

    dnf install --disablerepo="*" --enablerepo="aivax-repo" MariaDB-server MariaDB-client -y -q 

    cat <<EOF > /etc/my.cnf.d/custom.cnf
[mysqld]
innodb_buffer_pool_size = 4G
default_time_zone = '+00:00'
EOF

    systemctl enable mariadb
    systemctl start mariadb

    DB_USER="app"
    DB_PASS="app"
    DB_NAME="app"

mariadb <<EOF

CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

DROP USER IF EXISTS '${DB_USER}'@'%';
DROP USER IF EXISTS '${DB_USER}'@'localhost';
CREATE USER IF NOT EXISTS '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${DB_USER}'@'%' WITH GRANT OPTION;

CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';

GRANT CREATE, DROP, ALTER, INDEX, INSERT, UPDATE, DELETE, SELECT, LOCK TABLES ON *.* TO '${DB_USER}'@'localhost';

FLUSH PRIVILEGES;
EOF

    WRITE_LOG $FUNCNAME $LINENO "finish install mariadb"
}

function __install_nginx()
{
    WRITE_LOG $FUNCNAME $LINENO "start install nginx"
    
    dnf install --disablerepo="*" --enablerepo="aivax-repo" nginx -y -q

    #TODO: 여기까지는 설치 단계에서 처리 필요
    \cp -rf ./data-setup/nginx-setup/nginx-conf/aivax.conf /etc/nginx/conf.d/
    \cp -rf ./data-setup/nginx-setup/nginx-conf/ssl /etc/nginx/

    systemctl enable nginx
    systemctl start nginx

    nginx -t

    WRITE_LOG $FUNCNAME $LINENO "finish install nginx"
}

function __install_squid()
{
    WRITE_LOG $FUNCNAME $LINENO "start install squid"

    cp -rf ./data-setup/squid-setup/squid.conf /etc/squid/

    systemctl enable squid
    systemctl stop squid
    systemctl start squid

    WRITE_LOG $FUNCNAME $LINENO "finish install squid"
}

function __install_nodejs()
{
    WRITE_LOG $FUNCNAME $LINENO "start install nodejs"

    cp -rf ./extension/nodejs-install/node /home1/aivax/extension/

    chmod 755 /home1/aivax/extension/node

    WRITE_LOG $FUNCNAME $LINENO "finish install nodejs"
}

function __install_opensearch_config()
{
    
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
    WRITE_LOG $FUNCNAME $LINENO "start install opensearch"

    dnf install ./extension/rpm-install/3rd-repo/opensearch/v3.3.2/opensearch-3.3.2-linux-x64.rpm -y -q

    __install_opensearch_config

    __install_opensearch_data
    

    WRITE_LOG $FUNCNAME $LINENO "finish install opensearch"
}

function __install_slm()
{

    WRITE_LOG $FUNCNAME $LINENO "start install slm service"

    tar xzf ./extension/slm-install/slm.tar.gz  

    mv slm /home1/aivax/

    \cp -rf ./extension/slm-install/run.sh /home1/aivax/slm/
    \cp -rf ./extension/slm-install/stop.sh /home1/aivax/slm/

    WRITE_LOG $FUNCNAME $LINENO "finish install slm service"
    
}

function __patch_ai_engine()
{

    WRITE_LOG $FUNCNAME $LINENO "start install ai engine"

    tar xzf ./aivax-patch/ai_engine.tar.gz

    chmod 777 /var/run/

    \mv ai_engine /home1/aivax/

    cp -rf ./aivax-patch/systemd/ai-engine-install/ai-engine.service /etc/systemd/system/

    systemctl daemon-reload

    systemctl enable ai-engine.service
    systemctl start ai-engine.service

    WRITE_LOG $FUNCNAME $LINENO "finish install ai engine"
}

function __update_serial_license()
{

    systemctl start nginx
    systemctl start aivax-management

    sleep 1

    #license 파일 복사
    chmod 755 ./data-setup/license/multi_licenses_crypt
    chmod 755 ./data-setup/license/license_key_v2

    \cp -rf ./data-setup/license/multi_licenses_crypt /usr/local/bin/
    \cp -rf ./data-setup/license/license_key_v2 /usr/local/bin/

    # 버전 파일 실행, system python으로 수행되어야 한다.
    # license 정보, 우선 경로 파일을 읽거나, 기본값으로 할당한다.
    serial_key="SKRX4CWIS241299"
    license_key="af38d40897b5c174"
    SERIAL_FILE="./SKRX4CWIS241299.crt"

    version_default_file=$(realpath "${g_path}/.version")
    serial_file=$(realpath "${g_path}/SKRX4CWIS241299.crt")

    python version.py ${serial_key} ${license_key} ${SERIAL_FILE}

}

function __setup_aivax_venv()
{

    WRITE_LOG $FUNCNAME $LINENO "start setup aivax venv"

    
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

    cd - > /dev/null 2>&1

    WRITE_LOG $FUNCNAME $LINENO "finish setup aivax venv"
}

# 설치용 venv 생성, pip 사전 테스트 겸용.
function __setup_pip_venv_for_install()
{
    #TODO: 중복 코드는 installer에서 개선.
    VENV="./venv"

    if [ ! -d "$VENV" ]; then
        # /usr/local/bin/uv venv --python /usr/local/bin/python3.13 --seed "$VENV"
        /usr/local/bin/uv -qq venv --python /usr/local/bin/python3.13 "$VENV" > /dev/null 2>&1
        \cp -rf /usr/local/bin/uv ${VENV}/bin/
    fi

    source ./venv/bin/activate

    python -m ensurepip --default-pip > /dev/null 2>&1

    cd ./extension/python-install

    uv cache clean -q
    uv --quiet pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt
    
    cd - > /dev/null 2>&1
}

function __install_python()
{
    WRITE_LOG $FUNCNAME $LINENO "start install python"

    PYTHON_BIN="/usr/local/bin/python3.13"
    PYTHON_VERSION="3.13"

    if [ -x "$PYTHON_BIN" ] && "$PYTHON_BIN" --version 2>&1 | grep -q "Python ${PYTHON_VERSION}"
    then
        WRITE_LOG $FUNCNAME $LINENO "python ${PYTHON_VERSION} already installed"
    else
        
        tar xzf ./extension/python-install/usr.tar.gz -C ./extension/python-install/

        \cp -rf ./extension/python-install/usr/local/bin/* /usr/local/bin/
        \cp -rf ./extension/python-install/usr/local/lib/* /usr/local/lib/

        ldconfig
    fi

    \cp -rf ./extension/python-install/uv /usr/local/bin/

    WRITE_LOG $FUNCNAME $LINENO "finish install python"
}


function patch_aivax_source()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch aivax source"

    __setup_aivax_venv

    __patch_pipeline

    __patch_aivax_toolkit

    __patch_management

    __patch_sslproxy

    __patch_ai_engine

    __migrate_mariadb

    WRITE_LOG $FUNCNAME $LINENO "finish patch aivax source"
}

function __patch_pipeline()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch pipeline"

    tar xzf ./aivax-patch/pipeline.tar.gz 

    \mv -f pipeline /home1/aivax/

    cp -rf ./aivax-patch/systemd/pipeline-install/aivax-pipeline.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-pipeline
    systemctl start aivax-pipeline

    WRITE_LOG $FUNCNAME $LINENO "finish patch pipeline"
}

function __patch_aivax_toolkit()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax toolkit"

    tar xzf ./aivax-patch/toolkit.tar.gz 

    \mv -f toolkit /home1/aivax/

    cp -rf ./aivax-patch/systemd/toolkit-install/aivax-toolkit.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-toolkit
    systemctl start aivax-toolkit

    WRITE_LOG $FUNCNAME $LINENO "finish aivax toolkit"
}

function __patch_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch management"

    tar xzf ./aivax-patch/management.tar.gz 
    \mv -f management /home1/aivax/

    \cp -rf ./aivax-patch/systemd/management-install/aivax-management.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-management
    systemctl start aivax-management

    WRITE_LOG $FUNCNAME $LINENO "finish patch management"
}

function __patch_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch sslproxy"

    tar xzf ./aivax-patch/sslproxy.tar.gz 
    \mv -f sslproxy /home1/aivax/

    cp -rf ./extension/lib/libnet.so.1.8.0 /lib64/

    ln -sf /lib64/libnet.so.1.8.0 /lib64/libnet.so.9

    ldconfig

    cp -rf ./aivax-patch/systemd/sslproxy-install/aivax-sslproxy.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-sslproxy.service
    systemctl start aivax-sslproxy

    WRITE_LOG $FUNCNAME $LINENO "finish patch sslproxy"
}

function __migrate_mariadb()
{
    WRITE_LOG $FUNCNAME $LINENO "start migrate mariadb"

    systemctl start mariadb
    systemctl stop aivax-management

    tar xf ./extension/nodejs-install/node-v24.11.1-linux-x64.tar 

    \mv node-v24.11.1-linux-x64 /home1/aivax/extension/nodejs

    cd /home1/aivax/management/backend 

    export PATH=/home1/aivax/extension/nodejs/bin:$PATH

    export NODE_ENV=production

    /home1/aivax/extension/nodejs/bin/npm run migration:run > /dev/null

    cd - > /dev/null

    WRITE_LOG $FUNCNAME $LINENO "finish migrate mariadb"
}

function stop_aivax()
{
    WRITE_LOG $FUNCNAME $LINENO "stop aivax"

    if systemctl is-active --quiet nginx
    then
        systemctl stop nginx
    fi

    if systemctl is-active --quiet fluent-bit
    then
        systemctl stop fluent-bit
    fi

    if systemctl is-active --quiet opensearch
    then
        systemctl stop opensearch
    fi

    if systemctl is-active --quiet mariadb
    then
        systemctl stop mariadb
    fi

    if systemctl is-active --quiet aivax-management
    then
        systemctl stop aivax-management
    fi

    if systemctl is-active --quiet aivax-pipeline
    then
        systemctl stop aivax-pipeline
    fi

    if systemctl is-active --quiet aivax-sslproxy
    then
        systemctl stop aivax-sslproxy
    fi

    if systemctl is-active --quiet ai-engine.service
    then
        systemctl stop ai-engine.service
    fi

    if systemctl is-active --quiet squid
    then
        systemctl stop squid
    fi

    WRITE_LOG $FUNCNAME $LINENO "finish stop aivax"
}

function start_aivax()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax"

    systemctl daemon-reload

    systemctl enable nginx
    systemctl start nginx

    systemctl enable fluent-bit
    systemctl start fluent-bit    

    systemctl enable opensearch
    systemctl start opensearch

    systemctl enable mariadb
    systemctl start mariadb

    systemctl enable squid
    systemctl start squid

    systemctl enable aivax-management
    systemctl enable aivax-pipeline
    systemctl enable aivax-toolkit
    systemctl enable aivax-sslproxy
    systemctl enable ai-engine.service

    systemctl start aivax-management    
    systemctl start aivax-pipeline
    systemctl start aivax-toolkit
    
    systemctl start aivax-sslproxy

    systemctl start ai-engine.service

    WRITE_LOG $FUNCNAME $LINENO "finish start aivax"
}

function configure_after_install()
{
    WRITE_LOG $FUNCNAME $LINENO "start configure after install"

    wait_ready_opensearch

    __delete_opensearch_unused_index

    __backup_opensearch_snapshot

    __update_serial_license

    systemctl restart aivax-toolkit

    WRITE_LOG $FUNCNAME $LINENO "finish configure after install"

}

function __backup_opensearch_snapshot()
{

    mkdir -p /data/backup/opensearch_snapshot
    chown -hR opensearch:opensearch /data/backup/opensearch_snapshot
    chmod 750 /data/backup/opensearch_snapshot

    curl -sk -u admin:'Sniper123!@#' -X PUT "https://127.0.0.1:9200/_snapshot/aivax_snapshot" \
-H "Content-Type: application/json" \
-d '
{
  "type": "fs",
  "settings": {
    "location": "/data/backup/opensearch_snapshot"
  }
}'

}

function __delete_opensearch_unused_index()
{
    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/top_queries-*"     
    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/security-auditlog-*" 

    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/aivax_log_reindexed_*"

    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/_index_template/query_insights_top_queries_template" 

    curl -u 'admin:Sniper123!@#' -k -fs https://127.0.0.1:9200/aivax_log >/dev/null || curl -u 'admin:Sniper123!@#' -k -X PUT https://127.0.0.1:9200/aivax_log -H 'Content-Type: application/json' \
-d '{
  "settings": {
    "number_of_shards": 1,
    "number_of_replicas": 0
  }
}'

    curl -u admin:'Sniper123!@#' -sk https://127.0.0.1:9200/_cat/indices?v
}

function wait_ready_opensearch()
{

    WRITE_LOG $FUNCNAME $LINENO "wait ready opensearch"

    local RETRY=5
    local COUNT=0

    while [ $COUNT -lt $RETRY ]
    do
        RESPONSE=$(curl -sk -u admin:'Sniper123!@#' https://127.0.0.1:9200/_cluster/health)

        echo "$RESPONSE" | grep -q '"status"'

        if [ $? -eq 0 ]; then
            return 0
        fi

        COUNT=$((COUNT+1))

        echo "not ready yet... retry ${COUNT}/${RETRY}"
        WRITE_LOG $FUNCNAME $LINENO "wait start opensearch (${COUNT}/${RETRY})"

        sleep 2
    done

    return 1
}

function main()
{

    install_default_modules

    init_default_setup
    
    stop_aivax

    install_module

    patch_aivax_source

    start_aivax

    configure_after_install

}

main $@

# declare -A CONST_DEFINE

# CONST_DEFINE[aivax_rpm_repo_path]="extension/rpm/core-rpm/repos.d/aivax.repo"
# CONST_DEFINE[system_rpm_repo_path]="/etc/yum.repos.d/"

# # rpm 설치
# function __install_rpm_modules()
# {
#     #rpm이 정상이면, dnf로 설치할수 있다.
#     #예외처리는 프로그램으로. shell에서 실행하는 것 주의

#     dnf install jq --disablerepo="*" --enablerepo="aivax" -y

#     dnf install tree --disablerepo="*" --enablerepo="aivax" -y

#     dnf install sqlite --disablerepo="*" --enablerepo="aivax" -y

#     dnf install libreoffice-headless --disablerepo="*" --enablerepo="aivax" -y #TODO: 서버용으로 설치

#     dnf install tesseract --disablerepo="*" --enablerepo="aivax" -y 

#     dnf install tesseract-langpack-kor --disablerepo="*" --enablerepo="aivax" -y 

    

#     #TODO: C/C++ 개발 환경도 추가.

#     #TODO: opensearch, mariadb는 별도 설치.
# }


# function __install_rpm_repo()
# {
#     WRITE_LOG $FUNCNAME $LINENO "start install rpm repo"

#     # repo 설정, 기존 repos.d 복사후 한개만 설정
#     # aivax_repo_path=${CONST_DEFINE[aivax_rpm_repo_path]} => 일단 향후 고민.

#     # TODO: 프로그램에서는 경로는 config로 제어, 경로 변경시 바로 대응이 가능하도록 설계 할것

#     # config 복사
#     # systemd의 환경은 수정하지 않는다.
#     # mv /etc/yum.repos.d /etc/yum.repos.d_bak
#     mkdir -p /etc/yum.repos.d
#     # cp -rf ./extension/rpm/core-rpm/repos.d/aivax.repo /etc/yum.repos.d/
#     cp -rf ./extension/rpm-install/aivax.repo /etc/yum.respos.d/

#     # createrepo, dnf 실수 방지용으로 설치한다.
    
#     rpm -ivh createrepo/createrepo_c-libs-0.20.1-4.el9.x86_64.rpm createrepo/createrepo_c-0.20.1-4.el9.x86_64.rpm

#     #rpm은 미리 ./extensioni/rpm/ 디렉토리에 복사한채 빌드한다.

#     # repo 복사, 우선, 그냥 작성한다.
#     # rpm은 필요한 모듈만 복사한다.
#     # mkdir -p /home1/aivax/extension/rpm/
#     # mkdir -p /home1/aivax/extension/rpm/3rd-repo/mariadb/

#     # #기본 및 확장 rpm 복사
#     # cp -rf ./extension/rpm/base-repo /home1/aivax/extension/rpm/
#     # cp -rf ./extension/rpm/extra-repo /home1/aivax/extension/rpm/

#     # #mariadb, 버전 11.3.2
#     # cp -rf ./extension/rpm/3rd-repo/mariadb/v11.3.2 /home1/aivax/extension/rpm/3rd-repo/mariadb/

#     # #TODO: libreoffice, 분리해서 관리한다.
#     # cp -rf ./extension/rpm/3rd-repo/office-headless /home1/aivax/extension/rpm/3rd-repo/

#     # 기본 rpm
#     # jq, tree, strace, ltrace, tcpump
#     \cp -f ./extension/rpm-install/base-repo/*.rpm /home1/install/extension/rpm-repo/

#     # libreoffice
#     \cp -f ./extension/rpm-install/extra-repo/libreoffice-headless/*.rpm /home1/install/extension/rpm-repo/

#     # tesseract, ocr
#     \cp -f ./extension/rpm-install/extra-repo/tesseract/*.rpm /home1/install/extension/rpm-repo/

#     # nginx
#     \cp -f ./extension/rpm-install/extra-repo/nginx/*.rpm /home1/install/extension/rpm-repo/

#     # mariadb
#     \cp -f ./extension/rpm-install/extra-repo/mariadb/v11.3.2/*.rpm /home1/install/extension/rpm-repo/


#     #TODO: createrepo, 설치 시점에 다시 갱신한다.   
#     createrepo /home1/install/extension/rpm-repo/ 

#     dnf clean all
#     dnf makecache

#     # 테스트용, 출력
#     dnf repolist

#     WRITE_LOG $FUNCNAME $LINENO "finish install rpm repo"
# }

# 패치 시점이, 실제 구조는 프로그램으로 해결.
# function __install_sslproxy_env()
# {
#     WRITE_LOG $FUNCNAME $LINENO "start install sslproxy env"

#     # 이건 테스트 하면서, 
#     cp -rf ./extension/lib/libnet.so.1.8.0 /lib64/

#     #TODO -f 주의
#     ln -s /lib64/libnet.so.1.8.0 /lib64/libnet.so.1

#     WRITE_LOG $FUNCNAME $LINENO "finish install sslproxy env"
# }

# # 디스크, 자원등 설정, 초기에 설정해야 하는 기능과 묶어서 관리 필요
# function __setup_data_resource()
# {
#     WRITE_LOG $FUNCNAME $LINENO "start setup data resource"

#     WRITE_LOG $FUNCNAME $LINENO "finish data resource"
# }

# # 서비스 등록
# function __setup_aivax_service()
# {
#     WRITE_LOG $FUNCNAME $LINENO "start setup aivax service"

#     WRITE_LOG $FUNCNAME $LINENO "finish setup aivax service"
# }


# # aivax 프로세스 실행
# function __start_aivax_process()
# {
#     WRITE_LOG $FUNCNAME $LINENO "start aivax process"

#     systemctl start nginx
#     systemctl start opensearch
#     systemctl start fluent-bit
#     systemctl start mariadb

#     systemctl start aivax-management
#     systemctl start aivax-pipeline
#     systemctl start aivax-apiserver
#     systemctl start aivax-sslproxy

#     WRITE_LOG $FUNCNAME $LINENO "start aivax process"
# }

# #suricata 관련 설치
# function __install_suricata()
# {

#     WRITE_LOG $FUNCNAME $LINENO "start install suricata"

#     #설치 모듈은 lib/suricata에서 가져온다.
#     #config도 같이 관리

#     #suricata 관련
#     mkdir -p /var/log/suricata /var/run/suricata

#     mkdir -p /var/lib/suricata/rules
    

#     \cp -rf ./extension/lib/suricata/suricata* /usr/local/bin/
#     \cp -rf ./extension/lib/suricata/libxdp.so.1.5.0 /lib64/

#     chmod 755 /usr/local/bin/suricata*

#     ln -s /lib64/libxdp.so.1.5.0 /lib64/libxdp.so.1

#     # etc/config 복사
#     mkdir -p /etc/suricata

#     # \cp -rf ./extenstion/lib/suricata/config/classification.config /etc/suricata/
#     # \cp -rf ./extenstion/lib/suricata/config/reference.config /etc/suricata/
#     # \cp -rf ./extenstion/lib/suricata/config/suricata.yaml /etc/suricata/
#     # \cp -rf ./extenstion/lib/suricata/config/suricata_ai_mirror.lua /etc/suricata/
#     # \cp -rf ./extenstion/lib/suricata/config/threshold.config /etc/suricata/

#     \cp -rf ./extension/lib/suricata/etc/config/* /etc/suricata/

#     # /var/lib 복사, TODO: 향후 suricata로 확정되면, 소스 정리 필요
#     # mkdir /var/lib/suricata -p

#     \cp -rf ./extension/lib/suricata/var/lib/* /var/lib/

#     #서비스 등록
#     cp -rf ./aivax-patch/systemd/suricata-install/suricata.service /etc/systemd/system/

#     systemctl daemon-reload
#     systemctl enable suricata.service

#     WRITE_LOG $FUNCNAME $LINENO "finish install suricata"

# }

# function __install_opensearch()
# {
#     WRITE_LOG $FUNCNAME $LINENO "start install opensearch"

#     # opensearch 설치, opensearch는 별도로 설치한다. 옵션화, (제거할수 있다)
#     # 일단 작성후, 경로 또는 세부 테스트.
#     dnf install ./extension/rpm-install/3rd-repo/opensearch/v3.3.2/opensearch-3.3.2-linux-x64.rpm -y -q

#     #TODO: 여러 경로로 이동 필요, temp 경로롤 이용한다. (/home1/install/temp)

#     # 기본 디렉토리 생성, 두번 체크
#     # mkdir -p /home1/aivax/data_resource/opensearch/

#     # 설치후, 데이터 복사, config, 권한 설정 필요

#     # mkdir -p /home1/install/temp/opensearch

#     # mkdir -p /home1/install/temp/opensearch/config
#     # mkdir -p /home1/install/temp/opensearch/data

#     # tar xzf ./data-setup/opensearch-setup/opensearch.config.tar.gz -C /home1/install/temp/opensearch/config/
#     # tar xzvf ./extension/opensearch-install/opensearch.data.tar.gz -C /home1/install/temp/opensearch/data/

#     tar xzf ./data-setup/opensearch-setup/opensearch.config.tar.gz 

#     #과거 opensearch backup
#     \cp -rf /etc/opensearch /etc/opensearch.old
#     mv opensearch /etc/

#     chown -R opensearch:opensearch /etc/opensearch
#     chmod -R 750 /etc/opensearch

#     tar xzf ./data-setup/opensearch-setup/opensearch.data.tar.gz

#     # 상세 수정은 installer에서.
#     mv opensearch_docker opensearch

#     if [ -d /home1/aivax/data_resource/opensearch ]
#     then
#         mv /home1/aivax/data_resource/opensearch /home1/aivax/data_resource/opensearch.$(date +%Y%m%d%H%M)
#     fi

#     mv opensearch /home1/aivax/data_resource/

#     chown -R opensearch:opensearch /home1/aivax/data_resource/opensearch
#     chmod -R 750 /home1/aivax/data_resource/opensearch

#     # tar xzvf ./extension/opensearch-install/opensearch.config.tar.gz -C /home1/install/temp/opensearch/data/
#     # tar xzvf ./extension/opensearch-install/opensearch.data.tar.gz -C /home1/install/temp/opensearch/data/

#     # # TODO: opensearch 경로 변경 필요 => 프로그램으로 해결 필요

#     # #TODO: config 복사, 미세 조정 필요, pem 등 
#     # cp -rf /etc/opensearch/

#     # #TODO: data 복사 경로 복사 먼저 + opensearch.yml 쪽 먼저 수정 필요
#     # # 프로그램으로 해결하거나, sed 명령으로 수정 필요

#     # #TODO: 경로 확인 필요
#     # cp -rf /home1/install/temp/opensearch/data/ /var/lib/opensearch/

#     # # 권한 설정 추가, SNIPER OS는 경로가 다르다. 경로를 외부 설정으로 제어
#     # chown -R opensearch:opensearch /home1/aivax/data_resource/opensearch/
#     # chmod -R 750 /home1/aivax/data_resource/opensearch/

#     # chown -R opensearch:opensearch /etc/opensearch
#     # chmod -R 750 /etc/opensearch
#     # # chown -R opensearch:opensearch /var/lib/opensearch

#     # #VM size 설정
#     # sysctl -w vm.max_map_count=262144
#     echo "vm.max_map_count=262144" >> /etc/sysctl.conf #영구설정

#     #TODO: systemd 수정

#     #TODO: 설치 테스트, 장애 발생시 재생성 필요

#     # /etc/opensearch/opensearh.yml, 경로 변경, 우선 스크립트로
#     NEW_PATH="/home1/aivax/data_resource/opensearch"
#     CONFIG_FILE="/etc/opensearch/opensearch.yml"

#     sudo sed -i "s|path.data:.*|path.data: $NEW_PATH|g" "$CONFIG_FILE"
#     # sudo sed -i "s|path.logs:.*|path.logs: $NEW_PATH/logs|g" "$CONFIG_FILE"

#     # config 설정

#     # opensearch의 기본 service 파일 경로, /etc/로 변경 => 위험
# #     cat > /etc/systemd/system/opensearch.service <<EOF
# # [Unit]
# # Description=OpenSearch
# # After=network.target

# # [Service]
# # Type=simple
# # User=opensearch
# # Group=opensearch

# # Environment=OPENSEARCH_HOME=/data/opensearch
# # Environment=OPENSEARCH_PATH_CONF=/data/opensearch/config

# # ExecStart=/data/opensearch/bin/opensearch

# # Restart=always
# # LimitNOFILE=65535

# # [Install]
# # WantedBy=multi-user.target
# # EOF

#     cat > /etc/systemd/system/opensearch.service <<'EOF'
# [Unit]
# Description=OpenSearch
# Documentation=https://opensearch.org/
# Wants=network-online.target
# After=network-online.target

# [Service]
# Type=notify
# RuntimeDirectory=opensearch
# PrivateTmp=true
# EnvironmentFile=-/etc/default/opensearch
# EnvironmentFile=-/etc/sysconfig/opensearch
# User=opensearch
# Group=opensearch

# WorkingDirectory=/home1/aivax/data_resource/opensearch


# #ExecStartPre=/bin/mkdir -p /home1/aivax/data_resource/opensearch/tmp
# #ExecStartPre=/bin/chown opensearch:opensearch /home1/aivax/data_resource/opensearch/tmp

# ExecStartPre=/bin/mkdir -p /dev/shm/performanceanalyzer
# ExecStartPre=/bin/chown opensearch:opensearch /dev/shm/performanceanalyzer

# ExecStart=/usr/share/opensearch/bin/systemd-entrypoint -p ${PID_DIR}/opensearch.pid --quiet

# StandardOutput=journal
# StandardError=inherit
# SyslogIdentifier=opensearch

# LimitNOFILE=65535
# LimitNPROC=4096
# LimitAS=infinity
# LimitFSIZE=infinity

# TimeoutStopSec=0
# KillSignal=SIGTERM
# KillMode=process
# SendSIGKILL=no
# SuccessExitStatus=143

# TimeoutStartSec=75

# PrivateTmp=true
# ProtectSystem=full
# ProtectKernelTunables=true
# ProtectKernelModules=true
# ProtectControlGroups=true
# ProtectProc=invisible
# RestrictNamespaces=true
# LockPersonality=true
# NoNewPrivileges=true
# RestrictSUIDSGID=true
# RestrictRealtime=true
# ProtectHostname=true
# ProtectKernelLogs=true
# ProtectClock=true

# CapabilityBoundingSet=~CAP_SYS_ADMIN ~CAP_SYS_PTRACE ~CAP_NET_ADMIN ~CAP_BLOCK_SUSPEND ~CAP_LEASE ~CAP_SYS_PACCT ~CAP_SYS_TTY_CONFIG

# SystemCallArchitectures=native
# SystemCallFilter=seccomp mincore
# SystemCallFilter=madvise mlock mlock2 munlock get_mempolicy sched_getaffinity sched_setaffinity fcntl
# SystemCallFilter=@system-service
# SystemCallFilter=~@reboot
# SystemCallFilter=~@swap
# SystemCallErrorNumber=EPERM

# RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# ReadWritePaths=/home1/aivax/data_resource/opensearch
# ReadWritePaths=/dev/shm
# ReadWritePaths=-/etc/opensearch
# ReadWritePaths=-/mnt/snapshots

# #ReadOnlyPaths=-/etc/os-release -/usr/lib/os-release -/etc/system-release
# #ReadOnlyPaths=/proc/self/mountinfo /proc/diskstats
# #ReadOnlyPaths=/proc/self/cgroup
# #ReadOnlyPaths=/sys/fs/cgroup

# ReadOnlyPaths=/proc/self/cgroup /sys/fs/cgroup/cpu /sys/fs/cgroup/cpu/-
# ReadOnlyPaths=/sys/fs/cgroup/cpuacct /sys/fs/cgroup/cpuacct/- /sys/fs/cgroup/memory /sys/fs/cgroup/memory/-
# ReadOnlyPaths=/sys/fs/cgroup/system.slice/-

# RestrictNamespaces=true

# NoNewPrivileges=true

# # Memory and execution protection

# # Allow only native system calls
# SystemCallArchitectures=native
# # Service does not share key material with other services
# KeyringMode=private
# # Prevent changing ABI personality
# LockPersonality=true
# # Prevent creating SUID/SGID files
# RestrictSUIDSGID=true
# # Prevent acquiring realtime scheduling
# RestrictRealtime=true
# # Prevent changes to system hostname
# ProtectHostname=true
# # Prevent reading/writing kernel logs
# ProtectKernelLogs=true
# # Prevent tampering with the system clock
# ProtectClock=true

# [Install]
# WantedBy=multi-user.target
# EOF

#     WRITE_LOG $FUNCNAME $LINENO "finish install opensearch"
# }