
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

function main()
{
    __migrate_mariadb
}

main $@