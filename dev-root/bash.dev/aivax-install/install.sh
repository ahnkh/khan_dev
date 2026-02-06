g_path=$( cd "$(dirname "$0")" ; pwd )

TRACE_LOG="./trace-log"


declare -A CONST_DEFINE

CONST_DEFINE[aivax_rpm_repo_path]="extension/rpm/core-rpm/repos.d/aivax.repo"
CONST_DEFINE[system_rpm_repo_path]="/etc/yum.repos.d/"


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


####################################### 기본 모듈 설치

# 기본 설정 추가
function init_default_setup()
{

    WRITE_LOG $FUNCNAME $LINENO "start init default setup"

    # TODO: 디렉토리 이전, 네트워크 및 디스크 파티션도 생성 및 점검해야 한다.
    # /home1, /data 2개가 생성되어야 한다. -> sniperos 에서 지원하지 않으면 파티션 생성 기능이 만들어져야 한다.

    # 경로 생성, 향후 경로를 지정후 설정한다.
    # 패치, 재생성시 과거 데이터를 백업후 설정하는 기능이 필요하고, 백업 경로도 지정하는 기능 필요
    # 백업을 생성했다면, 존재여부를 확인하는 기능도 필요
    # 이경우 -> 사용자 대화식으로 UI, DIALOG 알람 기능이 필요하다.
    mkdir -p /home1/aivax/
    mkdir -p /home1/aivax/extension
    mkdir -p /home1/aivax/temp

    mkdir -p /home1/aivax/data_resource
    mkdir -p /home1/aivax/data_resource/attach_file

    mkdir -p /home1/aivax/.localconfig

    mkdir -p /home1/install/temp
    mkdir -p /home1/install/extension

    #TODO: opensearch data, 파티션 변경 필요 
    #/home1 => app, 또는 root, symbolic link
    #/data => 로그 저장영역

    #TODO: 설치 모듈, 필요한 설치 기능의 복사를 위해서 install 경로도 생성한다.
    #mkdir -p /home1/install

    # rocky linux 기본 tar가 설치 안되는 경우가 있다. tar는 별도로 추가.
    rpm -ivh tar-1.34-9.el9_7.x86_64.rpm

    # 설치후 정상점검 -> 프로그램화가 필요하다.

    # semanage 이슈, 프로그램에서 점검 우선 단기 대응
    #getenforce

    setenforce 0

    # 방화벽 확인. => 시작 단계에서

    WRITE_LOG $FUNCNAME $LINENO "finish init default setup"
}

# 모듈 설치
function install_module()
{

    WRITE_LOG $FUNCNAME $LINENO "start install module"
    # 하나씩 단계적으로 설치.

    # TODO: sniper_network, 확인 필요, 향후 자동화.

    # rpm 부터 설치, repo + rpm
    __install_rpm_repo

    # rpm 설치
    __install_rpm_modules

    __install_fluentbit

    __install_mariadb

    __install_nginx

    __install_nodejs

    __install_opensearch

    __install_python

    # __install_sslproxy_env

    WRITE_LOG $FUNCNAME $LINENO "finish install module"
}

function __install_rpm_repo()
{
    WRITE_LOG $FUNCNAME $LINENO "start install rpm repo"

    # repo 설정, 기존 repos.d 복사후 한개만 설정
    # aivax_repo_path=${CONST_DEFINE[aivax_rpm_repo_path]} => 일단 향후 고민.

    # TODO: 프로그램에서는 경로는 config로 제어, 경로 변경시 바로 대응이 가능하도록 설계 할것

    # config 복사    
    mv /etc/yum.repos.d /etc/yum.repos.d_bak
    mkdir -p /etc/yum.repos.d
    cp -rf ./extension/rpm/core-rpm/repos.d/aivax.repo /etc/yum.repos.d/

    # createrepo, dnf 실수 방지용으로 설치한다.

    cd core-rpm/createrepo
    rpm -ivh createrepo_c-libs-0.20.1-4.el9.x86_64.rpm createrepo_c-0.20.1-4.el9.x86_64.rpm


    #rpm은 미리 ./extensioni/rpm/ 디렉토리에 복사한채 빌드한다.

    # repo 복사, 우선, 그냥 작성한다.
    # rpm은 필요한 모듈만 복사한다.
    mkdir -p /home1/aivax/extension/rpm/
    mkdir -p /home1/aivax/extension/rpm/3rd-repo/mariadb/

    #기본 및 확장 rpm 복사
    cp -rf ./extension/rpm/base-repo /home1/aivax/extension/rpm/
    cp -rf ./extension/rpm/extra-repo /home1/aivax/extension/rpm/

    #mariadb, 버전 11.3.2
    cp -rf ./extension/rpm/3rd-repo/mariadb/v11.3.2 /home1/aivax/extension/rpm/3rd-repo/mariadb/

    #TODO: libreoffice, 분리해서 관리한다.
    cp -rf ./extension/rpm/3rd-repo/office-headless /home1/aivax/extension/rpm/3rd-repo/

    #TODO: createrepo, 설치 시점에 다시 갱신한다.    

    dnf clean all
    dnf makecache

    # 테스트용, 출력
    dnf repolist

    WRITE_LOG $FUNCNAME $LINENO "finish install rpm repo"
}


# rpm 저장, 변경된 구조, pseudo 코드
function __install_rpm_repo_v2()
{
    WRITE_LOG $FUNCNAME $LINENO "install rpm repo"

    # aivax.repo, 비활성화된 rpm

    #TODO: repo 경로는 고정이다. /home1/install
    \cp -f ./extension/rpm-install/aivax.repo /etc/yum.repos.d/

    #rpm 경로, 새로 만든다.
    mkdir -p /home1/install/extension/rpm-repo/

    #rpm 복사, 하나로 만든다.

    # 기본 rpm
    # jq, tree, strace, ltrace, tcpump
    \cp -f ./extension/rpm-install/base-repo/*.rpm /home1/install/extension/rpm-repo/

    # libreoffice
    \cp -f ./extension/rpm-install/extra-repo/libreoffice-headless/*.rpm /home1/install/extension/rpm-repo/

    # tesseract, ocr
    \cp -f ./extension/rpm-install/extra-repo/tesseract/*.rpm /home1/install/extension/rpm-repo/

    # nginx
    \cp -f ./extension/rpm-install/extra-repo/nginx/*.rpm /home1/install/extension/rpm-repo/

    # mariadb
    \cp -f ./extension/rpm-install/extra-repo/mariadb/v11.3.2/*.rpm /home1/install/extension/rpm-repo/

    #TODO: opensearch는 최종 확장 패키지로, 별도 설치.

    # 기본 rpm, createrepo 설치, 프로그램에서는 개별로 설치, 설치 오류 대응.
    rpm -ivh ./extension/rpm-install/createrepo/createrepo_c-libs-0.20.1-4.el9.x86_64.rpm 
    rpm -ivh ./extension/rpm-install/createrepo/createrepo_c-0.20.1-4.el9.x86_64.rpm

    #repo 다시 생성
    createrepo /home1/install/extension/rpm-repo/

    dnf clean all
    dnf makecache

    #테스트, 디버그용
    dnf repolist all

}

#rpm, 한번에 설치하도록 변경, rpm은 한군데에서 최초 설치.
function __istall_rpm_package_v2()
{
    dnf install jq --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install tree --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install sqlite --disablerepo="*" --enablerepo="aivax-repo" -y

    # file 추출, OCR 관련
    dnf install libreoffice-headless --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install tesseract --disablerepo="*" --enablerepo="aivax-repo" -y 

    dnf install tesseract-langpack-kor --disablerepo="*" --enablerepo="aivax-repo" -y 

    #maridb 설치
    dnf install MariaDB-server MariaDB-client --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install nginx --disablerepo="*" --enablerepo="aivax-repo" -y

    #TODO: C/C++ 개발 환경도 추가.

    #TODO: opensearch, mariadb는 별도 설치.
}

# rpm 설치
function __install_rpm_modules()
{
    #rpm이 정상이면, dnf로 설치할수 있다.
    #예외처리는 프로그램으로. shell에서 실행하는 것 주의

    dnf install jq --disablerepo="*" --enablerepo="aivax" -y

    dnf install tree --disablerepo="*" --enablerepo="aivax" -y

    dnf install sqlite --disablerepo="*" --enablerepo="aivax" -y

    dnf install libreoffice-headless --disablerepo="*" --enablerepo="aivax" -y #TODO: 서버용으로 설치

    dnf install tesseract --disablerepo="*" --enablerepo="aivax" -y 

    dnf install tesseract-langpack-kor --disablerepo="*" --enablerepo="aivax" -y 

    

    #TODO: C/C++ 개발 환경도 추가.

    #TODO: opensearch, mariadb는 별도 설치.
}


# fluentbit, 압축 해제 + 서비스 등록
function __install_fluentbit()
{
    WRITE_LOG $FUNCNAME $LINENO "start install fluent-bit"

    # extension, 그대로 복사한다.

    cp -rf ./extension/fluent-bit /home1/aivax/

    mkdir -p /home1/aivax/fluent-bit/db
    mkdir -p /home1/aivax/fluent-bit/trace_log

    #service, 경로문제, 프로그램에서 해결
    # 우선 fluent-bit 서비스 수동 절차 기술

    cp -rf fluent-bit.service /etc/systemd/system/

    #권한 문제, 대응 필요
    chmod 755 /home1/aivax/fluent-bit/fluent-bit

    systemctl daemon-reload
    systemctl enable fluent-bit.service
    systemctl start fluent-bit

    WRITE_LOG $FUNCNAME $LINENO "finish install fluent-bit"
}

function __install_mariadb()
{
    WRITE_LOG $FUNCNAME $LINENO "start install mariadb"

    # rpm이 있다는 가정하에, dnf로 설치 가능하다.
    # dnf 설치시, 스크립트로 설치하는 것 주의, -y 비 대화형 모드로 설치되어야 한다.
    dnf install MariaDB-server MariaDB-client -y

    #TODO: mariadb 기동후, setup 절차가 필요, mariadb는 서비스로 등록해야 할듯 하다.

    # mariadb --version , 버전 확인, 실행시점의 버전 11.3.2 -> 프로그램으로 분기 체크.

    # service 기동 상태 확인, 상세 체크는 프로그램으로 확인

    # 계정, IP 허용 설정
    # mariadb, 스크립트로 변경되어야 한다.
    # TODO: 인증 취약점, 계정, 비밀번호 다시 생성되어야 한다.

    # 아래는 예시
    # CREATE USER 'app'@'%' IDENTIFIED BY 'app';
    # GRANT ALL PRIVILEGES ON *.* TO 'app'@'%' WITH GRANT OPTION;
    # FLUSH PRIVILEGES;

    # CREATE USER 'app'@'localhost' IDENTIFIED BY 'app';
    # GRANT ALL PRIVILEGES ON app.* TO 'app'@'localhost';
    # FLUSH PRIVILEGES;

    # my.cnf 설정 변경 => 기본값으로 복사, 또는 프로그램으로 편집, 쉘스크립트는 지양한다.

    # #메모리 제한 확인
    # innodb_buffer_pool_size = 4G

    # [mysqld]
    # default_time_zone = '+00:00'

    WRITE_LOG $FUNCNAME $LINENO "finish install mariadb"
}

function __install_nginx()
{
    WRITE_LOG $FUNCNAME $LINENO "start install nginx"

    # yum이 설정되어, dnf로 설치한다.

    dnf install nginx -y

    # nginx config를 복사한다. TODO: 패키지의 압축을 해제하면, 필요한 몇을 제외하고는 압축되지 않는다.
    cp -rf ./extension/nginx/nginx-conf/aivax.conf /etc/nginx/conf.d/
    cp -rf ./extension/nginx/nginx-conf/ssl /etc/nginx/

    # 테스트, 아래 결과의 메시지 파싱, 프로그램으로 체크
    nginx -t

    systemctl enable nginx
    systemctl start nginx

    # systemctl reload nginx

    # 통신 체크 확인 필요, 프로그램으로 체크
    #ss -natup | grep 4000
    #systemctl status nginx

    WRITE_LOG $FUNCNAME $LINENO "finish install nginx"
}

function __install_nodejs()
{
    WRITE_LOG $FUNCNAME $LINENO "start install nodejs"

    # node.js extenstion 경로에 복사하면 끝
    cp -rf ./extension/nodejs/nodejs /home1/aivax/extension/

    chmod 755 /home1/aivax/extension/node

    # TODO: management 패치는, nodejs의 설치와 별도로 진행한다.
    # service 등록은 management 패치 시점에, 향후 패치 인스톨 고려시 다시.

    # 프로그램으로, 하나의 기능은 하나의 함수에서 독립적으로 관리, TDD

    WRITE_LOG $FUNCNAME $LINENO "finish install nodejs"
}

function __install_opensearch()
{
    WRITE_LOG $FUNCNAME $LINENO "start install opensearch"

    # opensearch 설치, opensearch는 별도로 설치한다. 옵션화, (제거할수 있다)
    # 일단 작성후, 경로 또는 세부 테스트.
    dnf install ./extension/rpm/3rd-repo/opensearch/v3.3.2/opensearch-3.3.2-linux-x64.rpm -y

    #TODO: 여러 경로로 이동 필요, temp 경로롤 이용한다. (/home1/install/temp)

    # 설치후, 데이터 복사, config, 권한 설정 필요

    mkdir -p /home1/install/temp/opensearch

    mkdir -p /home1/install/temp/opensearch/config
    mkdir -p /home1/install/temp/opensearch/data

    tar xzvf ./extension/opensearch-install/opensearch.config.tar.gz -C /home1/install/temp/opensearch/config/
    tar xzvf ./extension/opensearch-install/opensearch.data.tar.gz -C /home1/install/temp/opensearch/data/

    # TODO: opensearch 경로 변경 필요 => 프로그램으로 해결 필요

    #TODO: config 복사, 미세 조정 필요, pem 등 
    cp -rf /etc/opensearch/

    #TODO: data 복사 경로 복사 먼저 + opensearch.yml 쪽 먼저 수정 필요
    # 프로그램으로 해결하거나, sed 명령으로 수정 필요

    #TODO: 경로 확인 필요
    cp -rf /home1/install/temp/opensearch/data/ /var/lib/opensearch/

    # 권한 설정 추가, SNIPER OS는 경로가 다르다. 경로를 외부 설정으로 제어
    chown -R opensearch:opensearch /home1/aivax/data_resource/opensearch/
    chmod -R 750 /home1/aivax/data_resource/opensearch/

    chown -R opensearch:opensearch /etc/opensearch
    chmod -R 750 /etc/opensearch
    # chown -R opensearch:opensearch /var/lib/opensearch

    #VM size 설정
    sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf #영구설정

    #TODO: systemd 수정

    #TODO: 설치 테스트, 장애 발생시 재생성 필요

    WRITE_LOG $FUNCNAME $LINENO "finish install opensearch"
}

function __install_python()
{
    WRITE_LOG $FUNCNAME $LINENO "start install python"

    # python 복사, ldconfig
    cp -rf ./extension/python/usr/local/bin/* /usr/local/bin/
    cp -rf ./extension/python/usr/local/lib/* /usr/local/lib/

    #so 업데이트
    ldconfig

    #pip, uv로 교체
    cp -rf ./extension/python/uv /usr/local/bin/

    # venv 생성, 여기서 python 버전은 세부 config로 제어
    # python3.13 -m venv /home1/aivax/aivax-venv
    uv venv /home1/aivax/aivax-venv

    # bash 추가, sed
    source /home1/aivax/aivax-venv/bin/activate

    #개선 필요
    echo "source /home1/aivax/aivax-venv/bin/activate" >> /root/.bash_profile

    # offlinewheel
    # TODO: aivax-requirement는, 패키지 빌드 과정에서 생성
    # cp -rf requirements.최신.txt aivax-requirement.txt
    # pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt
    uv pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt

    # pycomlib 설치, 버전 주의.
    #uv pip install pycom* --force-reinstall

    uv pip install pycomlib-1.1.3-py3-none-any.whl --force-reinstall
    uv pip install pycomlibex-1.0.6-py3-none-any.whl --force-reinstall
    uv pip install pyservice-1.0.2-py3-none-any.whl --force-reinstall

    # 이후 pipeline 이하 appserver 설치는 다음 스텝으로.

    WRITE_LOG $FUNCNAME $LINENO "finish install python"
}

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

####################################### 외부 모듈

function build_install_slm()
{
    WRITE_LOG $FUNCNAME $LINENO "start build install slm"

    #TODO: 이건 run.sh 를 분석후, 소스에 추가한다.
    # run.sh 에 문제가 있는 부분이 있기는 하다.

    WRITE_LOG $FUNCNAME $LINENO "finish build install slm"
}


####################################### patch

# 소스 패치, 통합
function patch_aivax_source()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch aivax source"

    __patch_python_service

    __patch_management

    __patch_sslproxy

    WRITE_LOG $FUNCNAME $LINENO "finish patch aivax source"
}

function __patch_python_service()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch pipeline"

    # pipeline 패치
    # apiserver도 같이 묶어서, 프로그램에서 세분화 + 공통화

    # 서비스 등록, 향후 프로그램으로 설치와 패치 분리

    cp -rf aivax-pipeline.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-pipeline
    systemctl start aivax-pipeline

    WRITE_LOG $FUNCNAME $LINENO "finish patch pipeline"
}

function __patch_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch management"

    # management 패치

    # TODO: 빌드 스크립트에서 빌드된 manage 소스를 압축후 해제하는 정도로 마무리.

    tar xzvf management.tar.gz 
    mv management /home1/aivax/

    cp -rf aivax-management.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-management
    systemctl start aivax-management

    WRITE_LOG $FUNCNAME $LINENO "finish patch management"
}

function __patch_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch sslproxy"

    # libpcap 설치, 우선 작성후 프로그램에서 모듈 분리
    dnf install libpcap -y

    # 이건 테스트 하면서, 
    cp -rf ./extension/lib/libnet.so.1.8.0 /lib64/

    #TODO -f 주의
    ln -s /lib64/libnet.so.1.8.0 /lib64/libnet.so.9

    ldconfig

    # network 설정
    # ip eth 정보를 알아야 한다. 프로그램으로 해결
    bash network.sh enp1s0

    cp -rf aivax-sslproxy.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-sslproxy.service
    systemctl start aivax-sslproxy

    WRITE_LOG $FUNCNAME $LINENO "finish patch sslproxy"
}

####################################### service 등록 + 실행

function start_aivax()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax"

    __setup_data_resource

    __setup_aivax_service

    __start_aivax_process

    WRITE_LOG $FUNCNAME $LINENO "finish aivax"
}

# 디스크, 자원등 설정, 초기에 설정해야 하는 기능과 묶어서 관리 필요
function __setup_data_resource()
{
    WRITE_LOG $FUNCNAME $LINENO "start setup data resource"

    WRITE_LOG $FUNCNAME $LINENO "finish data resource"
}

# 서비스 등록
function __setup_aivax_service()
{
    WRITE_LOG $FUNCNAME $LINENO "start setup aivax service"

    WRITE_LOG $FUNCNAME $LINENO "finish setup aivax service"
}

# aivax 프로세스 실행
function __start_aivax_process()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax process"

    systemctl start nginx
    systemctl start opensearch
    systemctl start fluent-bit
    systemctl start mariadb

    systemctl start aivax-management
    systemctl start aivax-pipeline
    systemctl start aivax-apiserver
    systemctl start aivax-sslproxy

    WRITE_LOG $FUNCNAME $LINENO "start aivax process"
}

####################################### main, 실행

function main()
{

    # TODO: 경로를 생성해야 한다. 경로가 제일 먼저이다.
    init_default_setup

    # 최초, 모듈 설치
    install_module

    # 외부 오픈소스 실행
    build_install_slm

    # 소스 패치
    patch_aivax_source

    # 프로세스 기동
    start_aivax
}

main $@