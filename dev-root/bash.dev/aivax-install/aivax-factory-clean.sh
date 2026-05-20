
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
    # systemctl start mariadb

    # export PATH=/home1/aivax/extension/nodejs/bin:$PATH
    # export NODE_ENV=production

    # if [ -f "/home1/aivax/extension/nodejs/bin/npm" ] 
    # then
    #     cd /home1/aivax/management/backend 
    #     /home1/aivax/extension/nodejs/bin/npm run db:backup > /dev/null #2>&1
    #     cd - > /dev/null
    # fi

    # systemctl stop mariadb


    systemctl stop mariadb

    rm -rf /var/lib/mysql

    rm -rf /var/log/mariadb*
    rm -rf /var/log/mysql*

    #mariadb 설치형상은 유지
    dnf remove -y -q mariadb mariadb-server  --disablerepo='*'
    #dnf autoremove -y






    sleep 1
}

function clear_python()
{

    WRITE_LOG $FUNCNAME $LINENO "clear python"

    source /home1/aivax-venv/bin/activate
    deactivate

    rm -rf /home1/aivax-venv

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

    rm -rf /etc/systemd/system/aivax-management.service
    rm -rf /etc/systemd/system/aivax-pipeline.service
    rm -rf /etc/systemd/system/aivax-sslproxy.service
    rm -rf /etc/systemd/system/aivax-toolkit.service
    rm -rf /etc/systemd/system/opensearch.service

    # 다시 한번 종료
    SERVICES=(
        
        fluent-bit
        opensearch
        
        aivax-management
        aivax-pipeline
        aivax-sslproxy
        ai-engine
        aivax-toolkit
    )

    for svc in "${SERVICES[@]}"; do
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null

        rm -f "/etc/systemd/system/${svc}.service"
    done

    systemctl daemon-reload

    sleep 1
}

# function clear_os_env()
# {

# }

function stop_aivax_service()
{
    WRITE_LOG $FUNCNAME $LINENO "stop aivax service"

    SERVICES=(
        nginx
        fluent-bit
        opensearch
        mariadb
        squid
        
        aivax-management
        aivax-pipeline
        aivax-sslproxy
        ai-engine
        aivax-toolkit
    )

    for svc in "${SERVICES[@]}"; do
        systemctl stop "$svc" 2>/dev/null
        systemctl disable "$svc" 2>/dev/null

        # rm -f "/etc/systemd/system/${svc}.service"
    done

    sleep 1
}


function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start clear aivax"

    #서비스 종료, 제일 먼저 종료
    stop_aivax_service

    clear_mariadb

    clear_opensearch

    clear_python

    clear_service

    #경로, 제일 마지막에 삭제
    clear_aivax_patch

    clear_rpm

    # clear_os_env

    WRITE_LOG $FUNCNAME $LINENO "finish clear aivax"
}

main $@