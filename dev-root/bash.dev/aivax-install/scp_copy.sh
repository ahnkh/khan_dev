
g_path=$( cd "$(dirname "$0")" ; pwd )

git_root=/data/git-root
package_root=/data/data-root/aivax-install-root/aivax-install

git_branch="qa_release"

sslproxy_git_server="10.0.240.150"

package_server_ip="10.0.55.150"
package_server_port="22"


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


# toolkit build, 원격지로 복사한다. rsync는 배제
function build_toolkit()
{
    WRITE_LOG $FUNCNAME $LINENO "start build toolkit"

    cd ${git_root}/toolkit

    git pull

    cd ${git_root}

    tar -czf toolkit.tar.gz --exclude='.git' --exclude='.gitignore' toolkit/

    #원격 서버로 미리 이동
    scp -P ${package_server_port} -o ConnectTimeout=10 toolkit.tar.gz root@${package_server_ip}:${package_root}/aivax-patch/

    mv toolkit.tar.gz ${package_root}/aivax-patch/

    WRITE_LOG $FUNCNAME $LINENO "finish build toolkit"
}

# install.sh 복사, 향후 구조 변경시 같이 변경 필요
function update_install_script()
{
    WRITE_LOG $FUNCNAME $LINENO "start update install script"

    cd ${git_root}/khan_dev/dev-root/bash.dev/aivax-install

    cp -rfv install.sh ${package_root}/

    scp -P ${package_server_port} -o ConnectTimeout=10 install.sh ${package_server_ip}:${package_root}/

    WRITE_LOG $FUNCNAME $LINENO "finish update install script"
}

# pycomlib 복사
function update_pycomlib()
{

    WRITE_LOG $FUNCNAME $LINENO "start update pycom lib"

    # git_root=/data/git-root
    # package_root=/data/data-root/aivax-install-root/aivax-install

    cd ${git_root}/khan.pythonscript/
    svn update --username khan --password '1111' --non-interactive

    scp -P ${package_server_port} -o ConnectTimeout=10 ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pycomlib-1.1.7-py3-none-any.whl root@${package_server_ip}:${package_root}/extension/python-install/offline-wheel/
    scp -P ${package_server_port} -o ConnectTimeout=10 ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pycomlibex-1.1.2-py3-none-any.whl root@${package_server_ip}:${package_root}/extension/python-install/offline-wheel/

    scp -P ${package_server_port} -o ConnectTimeout=10 ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pyservice-1.0.3-py3-none-any.whl root@${package_server_ip}:${package_root}/extension/python-install/offline-wheel/
    scp -P ${package_server_port} -o ConnectTimeout=10 ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pytoolkit-1.0.0-py3-none-any.whl root@${package_server_ip}:${package_root}/extension/python-install/offline-wheel/

    cd -

    WRITE_LOG $FUNCNAME $LINENO "finish update pycom lib"
}

function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start scp copy"

    build_toolkit

    # 설치 스크립트, 향후 변경
    update_install_script

    #pycomlib 업데이트
    update_pycomlib

    # TODO: pip, rpm 업데이트, 이건 발생시 직접 복사

    WRITE_LOG $FUNCNAME $LINENO "finish scp copy"
}

main $@