
g_path=$( cd "$(dirname "$0")" ; pwd )

function WRITE_LOG()
{

    GREEN='\033[1;32m'
    NC='\033[0m' # No Color

    bold=$(tput bold)
    normal=$(tput sgr0)

    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo -e "${GREEN}[$(date '+%Y/%m/%d %H:%M:%S')]${NC}${bold} $3 ${normal}"
    
    # echo $string &>> ${g_path}/${TRACE_LOG}
}


####################################### main, 실행

function clear_aivax_patch()
{
    WRITE_LOG $FUNCNAME $LINENO "clear aivax patch"

    # aivax 관련 디렉토리 삭제
    # /home1/aivax
    # /home1/aivax.old

    rm -rf /home1/aivax
    rm -rf /home1/aivax.old

    sleep 1

}

function clear_opensearch()
{
    WRITE_LOG $FUNCNAME $LINENO "clear aivax log db"

    rm -rf /home1/opensearch

    rm -rf /etc/opensearch.old
    rm -rf /etc/opensearch

    sleep 1

}

# DB 초기화, 제일 먼저, node module 활용
function clear_mariadb()
{
    WRITE_LOG $FUNCNAME $LINENO "clear aivax policy db"

    #DB, 다시 기동
    systemctl start mariadb

    cd /home1/aivax/management/backend 

    export PATH=/home1/aivax/extension/nodejs/bin:$PATH
    export NODE_ENV=production

    /home1/aivax/extension/nodejs/bin/npm run db:backup > /dev/null #2>&1

    cd - > /dev/null

    systemctl stop mariadb

    sleep 1
}

function clear_python()
{

    WRITE_LOG $FUNCNAME $LINENO "clear python"
    deactivate

    rm -rf /usr/local/bin/python3.13
    rm -rf /usr/local/bin/python3.13-config
    rm -rf /usr/local/bin/pydoc3.13
    rm -rf /usr/local/bin/uv

    ldconfig

    sleep 1
}

function clear_rpm()
{
    WRITE_LOG $FUNCNAME $LINENO "clear rpm"

    rm -rf /home1/install/extension

    rm -rf /etc/yum.repos.d/aivax.repo

    sleep 1
}

function clear_etc_module()
{
    WRITE_LOG $FUNCNAME $LINENO "clear etc module"

    rm -rf /etc/nginx/conf.d/aivax.conf
    rm -rf /etc/nginx/ssl

    rm -rf /usr/local/bin/multi_licenses_crypt
    rm -rf /usr/local/bin/license_key_v2

    sleep 1
}

function clear_service()
{
    WRITE_LOG $FUNCNAME $LINENO "clear service"

    rm -rf /etc/systemd/system/fluent-bit.service

    rm -rf /etc/systemd/system/ai-engine.service

    systemctl daemon-reload

    sleep 1
}

# function clear_os_env()
# {

# }

function stop_aivax()
{
    WRITE_LOG $FUNCNAME $LINENO "stop aivax"

    systemctl stop nginx
    systemctl stop fluent-bit
    systemctl stop opensearch
    systemctl stop mariadb
    systemctl stop aivax-management
    systemctl stop aivax-pipeline
    systemctl stop aivax-sslproxy
    systemctl stop ai-engine.service
    systemctl stop squid

    sleep 1
}


function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start clear aivax"

    stop_service

    clear_mariadb

    clear_aivax_patch

    clear_opensearch

    clear_python

    clear_rpm

    # clear_os_env

    WRITE_LOG $FUNCNAME $LINENO "finish clear aivax"
}

main $@