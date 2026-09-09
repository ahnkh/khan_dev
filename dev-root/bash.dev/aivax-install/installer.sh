
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
    rpm -ih --quiet ./extension/rpm-install/extra-repo/dialog/dialog-1.3-32.20210117.el9.0.1.x86_64.rpm > /dev/null 2>&1

    __install_python

}

function ui_interface()
{
    # 현재경로, 설치용 venv를 만들어 보자. 모듈 최소화
    __setup_pip_venv_for_install

    #dialog, python, service module wrapper
    
    tar xzf ./aivax-patch/toolkit.tar.gz --strip-components=1 -C .

    # cd .pyinstall/toolkit

    # 테스트.
    python aivax_toolkit.py --debug --printlog --dummy

    cd - > /dev/null 2>&1

}


function __install_python()
{
    WRITE_LOG $FUNCNAME $LINENO "start install python"

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

    # tar xzf ./extension/python-install/usr.tar.gz -C ./extension/python-install/

    # \cp -rf ./extension/python-install/usr/local/bin/* /usr/local/bin/
    # \cp -rf ./extension/python-install/usr/local/lib/* /usr/local/lib/

    # #so 업데이트
    # ldconfig

    #pip, uv로 교체
    \cp -rf ./extension/python-install/uv /usr/local/bin/

    WRITE_LOG $FUNCNAME $LINENO "finish install python"
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

    # offlinewheel
    # TODO: aivax-requirement는, 패키지 빌드 과정에서 생성
    # cp -rf requirements.최신.txt aivax-requirement.txt
    # pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt
    # uv --quiet pip install --no-index --find-links=./extension/python-install/offline-wheel/ -r ./extension/python-install/aivax-requirement.txt

    uv cache clean -q
    uv --quiet pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt

    # pycomlib 설치, 버전 주의.
    #uv pip install pycom* --force-reinstall

    #TODO: 가급적 사용하지 않는 코드로 작성
    uv --quiet pip install ./offline-wheel/pycomlib-1.1.7-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pycomlibex-1.1.2-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pyservice-1.0.3-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pytoolkit-1.0.0-py3-none-any.whl --force-reinstall
    
    cd - > /dev/null 2>&1
}

function clear_install_resource()
{

    # cd .pyinstall/toolkit
    rm -rf .pyinstall

    #venv 종료
    # deactivate

    rm -rf aivax_toolkit.py
    rm -rf lib_include.py
    rm -rf mainapp
    rm -rf web_app_modules
    rm -rf local_resource
}

function main()
{

    install_default_modules

    ui_interface

    # 최종 자원 정리, 우선 제외
    clear_install_resource

}

main $@