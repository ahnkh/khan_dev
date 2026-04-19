
g_path=$( cd "$(dirname "$0")" ; pwd )

source ${g_path}/package.sh

TRACE_LOG="./trace-log"

git_root=/data/git-root
package_root=/data/data-root/aivax-install-root/aivax-install

function WRITE_LOG()
{

    GREEN='\033[1;32m'
    NC='\033[0m' # No Color

    bold=$(tput bold)
    normal=$(tput sgr0)

    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo -e "${GREEN}[$(date '+%Y/%m/%d %H:%M:%S')]${NC}${bold} $3 ${normal}"
    
    echo $string &>> ${g_path}/${TRACE_LOG}
}

# management build, 이동
# TODO: 경로등에 대해서는 installer, aivax-builder에서 개선
function build_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start build management"

    cd ${git_root}/aivax/apps/management

    git pull

    cd backend

    npm run build
    npm install

    cd ../frontend

    npm run build
    npm install

    cd ${git_root}/aivax/apps

    tar -czf management.tar.gz --exclude='.git' --exclude='.gitignore' management/

    mv management.tar.gz ${package_root}/aivax-patch/
    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish build management"
}

function build_pipeline()
{
    WRITE_LOG $FUNCNAME $LINENO "start build pipeline"

    cd ${git_root}/pipeline

    git pull

    cd ${git_root}

    tar -czf pipeline.tar.gz --exclude='.git' --exclude='.gitignore' pipeline/

    mv pipeline.tar.gz ${package_root}/aivax-patch/

    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish build pipeline"
}

function build_toolkit()
{
    WRITE_LOG $FUNCNAME $LINENO "start build toolkit"

    cd ${git_root}/toolkit

    git pull

    cd ${git_root}

    tar -czf toolkit.tar.gz --exclude='.git' --exclude='.gitignore' toolkit/

    mv toolkit.tar.gz ${package_root}/aivax-patch/

    WRITE_LOG $FUNCNAME $LINENO "finish build toolkit"
}

function update_install_script()
{
    cd ${git_root}/khan_dev/dev-root/bash.dev/aivax-install

    cp -rfv install.sh ${package_root}/
}


function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax build"

    build_management

    build_pipeline

    build_toolkit

    update_install_script

    #patch.sh
    patch


    WRITE_LOG $FUNCNAME $LINENO "finish aivax build"
}

main $@