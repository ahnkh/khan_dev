
g_path=$( cd "$(dirname "$0")" ; pwd )

function WRITE_LOG()
{

    GREEN='\033[1;32m'
    NC='\033[0m'

    bold=$(tput bold)
    normal=$(tput sgr0)

    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo -e "${GREEN}[$(date '+%Y/%m/%d %H:%M:%S')]${NC}${bold} $3 ${normal}"
    
    # echo $string &>> ${g_path}/${TRACE_LOG}
}

# 최초 기본 rpm 모듈 설치
function install_default_modules()
{
    WRITE_LOG $FUNCNAME $LINENO "install default modules"

    rpm -ih --quiet ./extension/rpm-install/extra-repo/dialog/dialog-1.3-32.20210117.el9.0.1.x86_64.rpm > /dev/null 2>&1

    __install_python

}

function ui_interface()
{
    __setup_pip_venv_for_install
    
    tar xzf ./aivax-patch/toolkit.tar.gz --strip-components=1 -C .

    ./.installer install

}


function __install_python()
{
    WRITE_LOG $FUNCNAME $LINENO "install python"

    # python 복사, ldconfig
    # 실행 최소화

    PYTHON_BIN="/usr/local/bin/python3.13"
    PYTHON_VERSION="3.13"

    # python 존재 + 버전 체크
    if [ -x "$PYTHON_BIN" ] && "$PYTHON_BIN" --version 2>&1 | grep -q "Python ${PYTHON_VERSION}"
    then
        #로그 미출력 => 향후 로그로 남긴다.
        WRITE_LOG $FUNCNAME $LINENO "python ${PYTHON_VERSION} already installed"
    else
        
        tar xzf ./extension/python-install/usr.tar.gz -C ./extension/python-install/

        \cp -rf ./extension/python-install/usr/local/bin/* /usr/local/bin/
        \cp -rf ./extension/python-install/usr/local/lib/* /usr/local/lib/

        ldconfig
    fi

    \cp -rf ./extension/python-install/uv /usr/local/bin/

}

function __setup_pip_venv_for_install()
{
    VENV="./venv"

    if [ ! -d "$VENV" ]; then
        /usr/local/bin/uv -qq venv --python /usr/local/bin/python3.13 "$VENV" > /dev/null 2>&1
        \cp -rf /usr/local/bin/uv ${VENV}/bin/
    fi

    source ./venv/bin/activate

    python -m ensurepip --default-pip > /dev/null 2>&1

    cd ./extension/python-install

    uv cache clean -q
    uv --quiet pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt

    uv --quiet pip install ./offline-wheel/pycomlib-1.1.7-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pycomlibex-1.1.2-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pyservice-1.0.3-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pytoolkit-1.0.0-py3-none-any.whl --force-reinstall
    
    cd - > /dev/null 2>&1
}

function clear_install_resource()
{

    rm -rf .pyinstall
    
    deactivate

    rm -rf aivax_toolkit.py
    rm -rf lib_include.py
    rm -rf mainapp
    rm -rf web_app_modules
    rm -rf local_resource
    rm -rf venv
    rm -rf __pycache__
    rm -rf .vscode

}

function main()
{

    WRITE_LOG $FUNCNAME $LINENO "start aivax install"

    install_default_modules

    ui_interface
    
    clear_install_resource

    WRITE_LOG $FUNCNAME $LINENO "finish aivax install"

}

main $@