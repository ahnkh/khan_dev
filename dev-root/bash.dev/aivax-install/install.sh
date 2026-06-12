g_path=$( cd "$(dirname "$0")" ; pwd )

TRACE_LOG="./trace-log"

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

function WRITE_ERROR()
{

    RED='\033[0;31m'    
    NC='\033[0m' # No Color

    bold=$(tput bold)
    normal=$(tput sgr0)
    
    echo -e "${RED}${bold}[$(date '+%Y/%m/%d %H:%M:%S')] $3 ${normal} ${NC} "

    #$$ = pid
    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo $string &>> ${g_path}/${log_file}
}

####################################### 기본 모듈 설치

# 최초 기본 rpm 모듈 설치
function install_default_modules()
{
    # WRITE_LOG $FUNCNAME $LINENO "install default rpm"

    rpm -ih --quiet ./extension/rpm-install/extra-repo/dialog/dialog-1.3-32.20210117.el9.0.1.x86_64.rpm > /dev/null 2>&1

    #시작부터 python 설치
    __install_python

}

function ui_interface()
{
    # 현재경로, 설치용 venv를 만들어 보자. 모듈 최소화
    __setup_pip_venv_for_install

    #dialog, python, service module wrapper

    rm -rf .pyinstall
    mkdir -p .pyinstall
    tar xzf ./aivax-patch/toolkit.tar.gz -C .pyinstall

    cd .pyinstall/toolkit

    # 테스트.
    # python aivax_toolkit.py --debug --printlog --dummy

    cd - > /dev/null 2>&1

}


# 기본 설정 추가
function init_default_setup()
{

    WRITE_LOG $FUNCNAME $LINENO "start init default setup"

    # TODO: 디렉토리 이전, 네트워크 및 디스크 파티션도 생성 및 점검해야 한다.
    # /home1, /data 2개가 생성되어야 한다. -> sniperos 에서 지원하지 않으면 파티션 생성 기능이 만들어져야 한다.
    mkdir -p /home1/aivax.old

    TODAY=$(date +%Y%m%d)
    #기존 디렉토리, 존재하면 이동, 없으면 그냥 오류, TODO: 삭제는 하지 않는다. 위험.
    #향후 installer에서 상세 오류 점검.
    #rm -rf /home1/aivax.old/aivax.$TODAY

    if [ -d /home1/aivax.old/aivax.$TODAY ]
    then
        mv /home1/aivax.old/aivax.$TODAY /home1/aivax.old/aivax.$(date +%Y%m%d%H%M)
    fi

    if [ -d /home1/aivax ] 
    then
        mv /home1/aivax /home1/aivax.old/aivax.$TODAY
    fi

    #디렉토리, 존재하면 /home1/aivax.old/aivax.[오늘날짜 경로에 백업한다.]

    # 경로 생성, 향후 경로를 지정후 설정한다.
    # 패치, 재생성시 과거 데이터를 백업후 설정하는 기능이 필요하고, 백업 경로도 지정하는 기능 필요
    # 백업을 생성했다면, 존재여부를 확인하는 기능도 필요
    # 이경우 -> 사용자 대화식으로 UI, DIALOG 알람 기능이 필요하다.
    mkdir -p /home1/aivax/
    mkdir -p /home1/aivax/extension
    # mkdir -p /home1/aivax/temp

    #불필요 경로, 삭제        
    mkdir -p /home1/aivax/data_resource && rm -rf /home1/aivax/data_resources
    # mkdir -p /home1/aivax/data_resource/{attach_file,opensearch}
    mkdir -p /home1/aivax/data_resource/attach_file

    mkdir -p /home1/aivax/data_resource/policy_signal

    # mkdir -p /home1/aivax/.localconfig

    # mkdir -p /home1/install/temp
    # mkdir -p /home1/install/extension

    mkdir -p /home1/install/extension/rpm-repo/

    # 기본 파일 복사
    # TODO: 파일 존재 여부 체크, 없을때만 복사해야 한다.
    \cp -rf ./data-setup/etc-resource/aivax_policy.json /home1/aivax/data_resource/policy_signal/
    \cp -rf ./data-setup/etc-resource/block.html /home1/aivax/data_resource/

    #TODO: opensearch data, 파티션 변경 필요 
    #/home1 => app, 또는 root, symbolic link
    #/data => 로그 저장영역

    #TODO: 설치 모듈, 필요한 설치 기능의 복사를 위해서 install 경로도 생성한다.
    #mkdir -p /home1/install

    # rocky linux 기본 tar가 설치 안되는 경우가 있다. tar는 별도로 추가.
    # tar는 제외, tar는 수동으로 설치하고, 압축을 푼 이후부터.. tar는 인스톨러에서 해결하자.
    # rpm -ivh tar-1.34-9.el9_7.x86_64.rpm

    # 설치후 정상점검 -> 프로그램화가 필요하다.

    # semanage 이슈, 프로그램에서 점검 우선 단기 대응
    #getenforce

    setenforce 0

    # 방화벽 확인. => 시작 단계에서

    # sniperos - dnf에 대한 예외처리
    # dnf 위치는 기본 /usr/bin/dnf
    # dnf 이슈, 상세 처리는 installer에서.

    # dnf설정, 향후 installer에서 옵션화
    chmod 755 /usr/bin/dnf

    # timezone 설정, 향후 installer에서 옵션화
    sudo ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime

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
    # __install_rpm_modules
    __istall_rpm_package

    # python, 제일 먼저 설치하도록 변경
    # __install_python

    __install_fluentbit

    __install_mariadb

    __install_nginx

    __install_nodejs

    __install_squid

    __install_opensearch

    # suricata 제거
    # __install_suricata

    # __install_sslproxy_env

    WRITE_LOG $FUNCNAME $LINENO "finish install module"
}

# rpm 저장, 변경된 구조, pseudo 코드
function __install_rpm_repo()
{
    WRITE_LOG $FUNCNAME $LINENO "start install rpm repo"

    WRITE_LOG $FUNCNAME $LINENO "install rpm repo"

    # aivax.repo, 비활성화된 rpm

    #repos.d에서 파일을 삭제한다.
    # if [ -d /etc/yum.repos.d_bak ]
    # then
    #     rm -rf /etc/yum.repos.d_bak
    # fi
    # rm -rf /etc/yum.repos.d_bak
    mkdir -p /etc/yum.repos.d_bak
    mkdir -p /etc/yum.repos.d

    \cp -rf /etc/yum.repos.d/* /etc/yum.repos.d_bak/

    # 오프라인 환경 대비, aivax외 repo는 삭제한다.
    rm -rf /etc/yum.repos.d/*.repo

    #TODO: repo 경로는 고정이다. /home1/install
    \cp -f ./extension/rpm-install/aivax.repo /etc/yum.repos.d/

    #rpm 경로, 새로 만든다.
    mkdir -p /home1/install/extension/rpm-repo/

    #rpm 복사, 하나로 만든다.

    # 기본 rpm
    # jq, tree, strace, ltrace, tcpump
    \cp -f ./extension/rpm-install/base-repo/*.rpm /home1/install/extension/rpm-repo/

    # libreoffice
    # \cp -f ./extension/rpm-install/extra-repo/libreoffice-headless/*.rpm /home1/install/extension/rpm-repo/
    \cp -f ./extension/rpm-install/extra-repo/libreoffice-full/*.rpm /home1/install/extension/rpm-repo/

    # tesseract, ocr
    \cp -f ./extension/rpm-install/extra-repo/tesseract/*.rpm /home1/install/extension/rpm-repo/

    # nginx

    # nginx 1.30으로 교체
    # \cp -f ./extension/rpm-install/extra-repo/nginx/*.rpm /home1/install/extension/rpm-repo/
    \cp -f ./extension/rpm-install/extra-repo/nginx/v1.30/*.rpm /home1/install/extension/rpm-repo/

    # mariadb
    \cp -f ./extension/rpm-install/extra-repo/perl/*.rpm /home1/install/extension/rpm-repo/
    \cp -f ./extension/rpm-install/extra-repo/mariadb/v11.3.2/*.rpm /home1/install/extension/rpm-repo/

    # zip
    \cp -f ./extension/rpm-install/extra-repo/zip/*.rpm /home1/install/extension/rpm-repo/

    # squid proxy
    \cp -f ./extension/rpm-install/extra-repo/squid_proxy/*.rpm /home1/install/extension/rpm-repo/


    # suricata -> 제거
    # \cp -f ./extension/rpm-install/extra-repo/suricata/*.rpm /home1/install/extension/rpm-repo/

    #TODO: opensearch는 최종 확장 패키지로, 별도 설치.

    # 기본 rpm, createrepo 설치, 프로그램에서는 개별로 설치, 설치 오류 대응.
    # TODO: 실제 installer에서는 각 설치 단계별로 로그를 상세히 남긴다.
    rpm -ih --quiet ./extension/rpm-install/createrepo/createrepo_c-libs-0.20.1-4.el9.x86_64.rpm > /dev/null #2>&1
    rpm -ih --quiet ./extension/rpm-install/createrepo/createrepo_c-0.20.1-4.el9.x86_64.rpm > /dev/null #2>&1

    #repo 다시 생성
    createrepo /home1/install/extension/rpm-repo/

    dnf clean all
    dnf makecache

    #테스트, 디버그용
    # dnf repolist all

    WRITE_LOG $FUNCNAME $LINENO "finish install rpm package"

}

#rpm, 한번에 설치하도록 변경, rpm은 한군데에서 최초 설치.
function __istall_rpm_package()
{
    WRITE_LOG $FUNCNAME $LINENO "start install rpm package"

    dnf install jq --disablerepo="*" --enablerepo="aivax-repo" -y -q

    # dnf install tree --disablerepo="*" --enablerepo="aivax-repo" -y -q

    # dnf install sqlite --disablerepo="*" --enablerepo="aivax-repo" -y -q

    # file 추출, OCR 관련
    # dnf install libreoffice-headless --disablerepo="*" --enablerepo="aivax-repo" -y -q
    dnf install libreoffice* --disablerepo="*" --enablerepo="aivax-repo" -y -q

    dnf install tesseract --disablerepo="*" --enablerepo="aivax-repo" -y -q 

    dnf install tesseract-langpack-kor --disablerepo="*" --enablerepo="aivax-repo" -y -q 

    #maridb 설치
    dnf install MariaDB-server MariaDB-client --disablerepo="*" --enablerepo="aivax-repo" -y -q

    #TODO: C/C++ 개발 환경
    dnf install libpcap --disablerepo="*" --enablerepo="aivax-repo" -y -q

    # DB 설치 관련
    dnf install --disablerepo="*" --enablerepo="aivax-repo" MariaDB-server MariaDB-client -y -q 

    # nginx
    #TODO: 1.20 -> 1.30 업그레이드
    dnf remove nginx nginx-core nginx-filesystem -y -q

    dnf install --disablerepo="*" --enablerepo="aivax-repo" nginx -y -q

    # zip, unzip
    dnf install --disablerepo="*" --enablerepo="aivax-repo" zip -y -q
    dnf install --disablerepo="*" --enablerepo="aivax-repo" unzip -y -q

    # squid proxy
    dnf install --disablerepo="*" --enablerepo="aivax-repo" squid -y -q

    #TODO: opensearch, mariadb는 별도 설치.

    # suricata 관련, 제거

    # dnf install lz4 file-libs libcap-ng libbpf libxdp elfutils-libelf libnet jansson libyaml --disablerepo="*" --enablerepo="aivax-repo" -y -q

    # dnf install pcre2 zlib libpcap libzstd libibverbs libnl3 nss --disablerepo="*" --enablerepo="aivax-repo" -y -q

    # dnf install lua lua-devel lua-socket python3-pyyaml --disablerepo="*" --enablerepo="aivax-repo" -y -q

    WRITE_LOG $FUNCNAME $LINENO "finish install rpm package"
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

    cp -rf ./extension/fluent-bit/fluent-bit.service /etc/systemd/system/

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
    # TODO: 두번 설치/체크한다.
    dnf install --disablerepo="*" --enablerepo="aivax-repo" MariaDB-server MariaDB-client -y -q 

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

    cat <<EOF > /etc/my.cnf.d/custom.cnf
[mysqld]
innodb_buffer_pool_size = 4G
default_time_zone = '+00:00'
EOF

    #먼저 기동해야 한다.
    systemctl enable mariadb
    systemctl start mariadb

    DB_USER="app"
    DB_PASS="app"
    DB_NAME="app"

    # mariadb -u root < ./data-setup/mariadb-setup/aivax_db_dump.sql

#TODO: drop이 되어야 한다.
# mariadb <<EOF
# DROP DATABASE IF EXISTS ${DB_NAME};
# CREATE DATABASE ${DB_NAME};
# EOF
    
# if mariadb -e "USE ${DB_NAME}" 2>/dev/null; then    
#     WRITE_ERROR $FUNCNAME $LINENO "DB already exists. Skip import."
# else
#     mariadb ${DB_NAME} < dump.sql
# fi

    #26.05.01 dump 기능 제거, npm 의 migration으로 대체 (create까지 된다는 가정으로 진행)
    #mariadb ${DB_NAME} < ./data-setup/mariadb-setup/aivax_db_dump.sql

    #TODO: GRANT 다시 정리 필요
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

FLUSH PRIVILEGES;
EOF

    # 체크 필요, migration dump가 아닌, 점검된 스크립트가 필요할것 같다.
    # dump는 필요할때 1번만 추가
    # grep -i user dump.sql
    # grep -i grant dump.sql


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
    
    dnf install --disablerepo="*" --enablerepo="aivax-repo" nginx -y -q

    # nginx config를 복사한다. TODO: 패키지의 압축을 해제하면, 필요한 몇을 제외하고는 압축되지 않는다.
    # cp -rf ./extension/nginx/nginx-conf/aivax.conf /etc/nginx/conf.d/
    # cp -rf ./extension/nginx/nginx-conf/ssl /etc/nginx/

    \cp -rf ./data-setup/nginx-setup/nginx-conf/aivax.conf /etc/nginx/conf.d/
    \cp -rf ./data-setup/nginx-setup/nginx-conf/ssl /etc/nginx/

    # 테스트, 아래 결과의 메시지 파싱, 프로그램으로 체크
    nginx -t

    systemctl enable nginx
    systemctl start nginx

    # systemctl reload nginx

    # TODO: port, ip 등은 외부에서 지정할수 있어야 한다.
    # port가 변경되면, 재설치 하도록 옵션화, 세부 프로그래밍이 되어야 한다.

    # 통신 체크 확인 필요, 프로그램으로 체크
    #ss -natup | grep 4000
    #systemctl status nginx

    WRITE_LOG $FUNCNAME $LINENO "finish install nginx"
}

#squid proxy, config 교체
function __install_squid()
{
    WRITE_LOG $FUNCNAME $LINENO "start install squid"

    cp -rf ./data-setup/squid-setup/squid.conf /etc/squid/

    systemctl enable squid
    systemctl stop squid
    systemctl start squid #시간이 소요될수 있다.

    WRITE_LOG $FUNCNAME $LINENO "finish install squid"
}

function __install_nodejs()
{
    WRITE_LOG $FUNCNAME $LINENO "start install nodejs"

    # node.js extenstion 경로에 복사하면 끝
    cp -rf ./extension/nodejs-install/node /home1/aivax/extension/

    chmod 755 /home1/aivax/extension/node

    # node.js, systemd 등록 필요 => aivax.conf를 별도로 추가한다. (다만 인스톨러에서 생성하고, /home1/aivax 안에서 관리한다.)

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
    dnf install ./extension/rpm-install/3rd-repo/opensearch/v3.3.2/opensearch-3.3.2-linux-x64.rpm -y -q

    #TODO: 디렉토리 존재여부, 디렉토리가 존재하고, 설치 되어 있으면 skip 한다.
    if [ -d /home1/opensearch ]
    then
        # mv /home1/aivax/data_resource/opensearch /home1/aivax/data_resource/opensearch.$(date +%Y%m%d%H%M)
        # TODO: 종료코드, 현재시점은 최초 설치만 고려
        WRITE_LOG $FUNCNAME $LINENO "opensearch is already installed, stop install"
        return
    fi

    

    #TODO: 여러 경로로 이동 필요, temp 경로롤 이용한다. (/home1/install/temp)

    # 기본 디렉토리 생성, 두번 체크
    # mkdir -p /home1/aivax/data_resource/opensearch/

    # 설치후, 데이터 복사, config, 권한 설정 필요

    # mkdir -p /home1/install/temp/opensearch

    # mkdir -p /home1/install/temp/opensearch/config
    # mkdir -p /home1/install/temp/opensearch/data

    # tar xzf ./data-setup/opensearch-setup/opensearch.config.tar.gz -C /home1/install/temp/opensearch/config/
    # tar xzvf ./extension/opensearch-install/opensearch.data.tar.gz -C /home1/install/temp/opensearch/data/

    rm -rf /tmp/install-temp/opensearch-config
    rm -rf /tmp/install-temp/opensearch-data

    mkdir -p /tmp/install-temp/opensearch-config
    tar xzf ./data-setup/opensearch-setup/opensearch.config.tar.gz  -C /tmp/install-temp/opensearch-config

    #과거 opensearch backup
    # 임시, 삭제가 되어서는 안된다.
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

    mkdir -p /tmp/install-temp/opensearch-data
    tar xzf ./data-setup/opensearch-setup/opensearch.data.tar.gz -C /tmp/install-temp/opensearch-data/

    # 상세 수정은 installer에서.
    mv /tmp/install-temp/opensearch-data/opensearch_docker /tmp/install-temp/opensearch-data/opensearch

    #TODO: 경로 변경, 일단 스크립트에서는 수동으로 교체, installer에서 정식으로 교체

    # if [ -d /home1/aivax/data_resource/opensearch ]
    # then
    #     mv /home1/aivax/data_resource/opensearch /home1/aivax/data_resource/opensearch.$(date +%Y%m%d%H%M)
    # fi

    # mv /tmp/install-temp/opensearch-data/opensearch /home1/aivax/data_resource/

    # chown -R opensearch:opensearch /home1/aivax/data_resource/opensearch
    # chmod -R 750 /home1/aivax/data_resource/opensearch

    # 과거 데이터 migration, 일단 임시, 상세 제어 필요
    #TODO: 이미 경로가 변경되었다. 호출될 수 없는 구문 => 여기는 좀더 세밀하게 조정한다.
    # if [ -d /home1/aivax/data_resource/opensearch ]
    # then
    #     WRITE_LOG $FUNCNAME $LINENO "restore opensearch data"
    #     mv /home1/aivax/data_resource/opensearch /home1/
    # else
    #     
    # fi

    #기본 설치 - installer에서 조금더 보강
    mv /tmp/install-temp/opensearch-data/opensearch /home1/

    chown -R opensearch:opensearch /home1/opensearch
    chmod -R 750 /home1/opensearch

    # tar xzvf ./extension/opensearch-install/opensearch.config.tar.gz -C /home1/install/temp/opensearch/data/
    # tar xzvf ./extension/opensearch-install/opensearch.data.tar.gz -C /home1/install/temp/opensearch/data/

    # # TODO: opensearch 경로 변경 필요 => 프로그램으로 해결 필요

    # #TODO: config 복사, 미세 조정 필요, pem 등
    # cp -rf /etc/opensearch/

    # #TODO: data 복사 경로 복사 먼저 + opensearch.yml 쪽 먼저 수정 필요
    # # 프로그램으로 해결하거나, sed 명령으로 수정 필요

    # #TODO: 경로 확인 필요
    # cp -rf /home1/install/temp/opensearch/data/ /var/lib/opensearch/

    # # 권한 설정 추가, SNIPER OS는 경로가 다르다. 경로를 외부 설정으로 제어
    # chown -R opensearch:opensearch /home1/aivax/data_resource/opensearch/
    # chmod -R 750 /home1/aivax/data_resource/opensearch/

    # chown -R opensearch:opensearch /etc/opensearch
    # chmod -R 750 /etc/opensearch
    # # chown -R opensearch:opensearch /var/lib/opensearch

    # #VM size 설정
    # sysctl -w vm.max_map_count=262144
    echo "vm.max_map_count=262144" >> /etc/sysctl.conf #영구설정

    #TODO: systemd 수정

    #TODO: 설치 테스트, 장애 발생시 재생성 필요

    # /etc/opensearch/opensearh.yml, 경로 변경, 우선 스크립트로
    # NEW_PATH="/home1/aivax/data_resource/opensearch"
    NEW_PATH="/home1/opensearch"
    CONFIG_FILE="/etc/opensearch/opensearch.yml"

    sudo sed -i "s|path.data:.*|path.data: $NEW_PATH|g" "$CONFIG_FILE"
    # sudo sed -i "s|path.logs:.*|path.logs: $NEW_PATH/logs|g" "$CONFIG_FILE"

    # config 설정

    # opensearch의 기본 service 파일 경로, /etc/로 변경 => 위험
#     cat > /etc/systemd/system/opensearch.service <<EOF
# [Unit]
# Description=OpenSearch
# After=network.target

# [Service]
# Type=simple
# User=opensearch
# Group=opensearch

# Environment=OPENSEARCH_HOME=/data/opensearch
# Environment=OPENSEARCH_PATH_CONF=/data/opensearch/config

# ExecStart=/data/opensearch/bin/opensearch

# Restart=always
# LimitNOFILE=65535

# [Install]
# WantedBy=multi-user.target
# EOF

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

#WorkingDirectory=/home1/aivax/data_resource/opensearch
WorkingDirectory=/home1/opensearch

#ExecStartPre=/bin/mkdir -p /home1/aivax/data_resource/opensearch/tmp
#ExecStartPre=/bin/chown opensearch:opensearch /home1/aivax/data_resource/opensearch/tmp

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

ReadWritePaths=/home1/opensearch
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

    WRITE_LOG $FUNCNAME $LINENO "finish install opensearch"
}

#ai 엔진 설치
function __patch_ai_engine()
{

    WRITE_LOG $FUNCNAME $LINENO "start install ai engine"

    tar xzf ./aivax-patch/ai_engine.tar.gz

    # AI 엔진 소켓 경로 권한 부여
    chmod 777 /var/run/

    \mv ai_engine /home1/aivax/

    # cp -rf ./aivax-patch/systemd/ai-engine-install/ai-engine@.service /etc/systemd/system/
    cp -rf ./aivax-patch/systemd/ai-engine-install/ai-engine.service /etc/systemd/system/

    systemctl daemon-reload

    # systemctl enable ai-engine@{1..4}.service

    #ai engine 하나만 사용
    # for i in 1 2 3 4; do
    #     systemctl enable ai-engine@$i.service
    #     # systemctl start ai-engine@$i.service
    # done

    systemctl enable ai-engine.service
    systemctl start ai-engine.service

    WRITE_LOG $FUNCNAME $LINENO "finish install ai engine"
}

# serial license 업데이트, TODO: installer는 상세 처리
function __update_serial_license()
{

    WRITE_LOG $FUNCNAME $LINENO "start patch etc util"

    #nginx, management, 혹시 모르니 시작시킨다.
    systemctl start nginx
    systemctl start aivax-management

    # 1초 대기
    sleep 1

    #license 파일 복사
    chmod 755 ./data-setup/license/multi_licenses_crypt
    chmod 755 ./data-setup/license/license_key_v2

    \cp -rf ./data-setup/license/multi_licenses_crypt /usr/local/bin/
    \cp -rf ./data-setup/license/license_key_v2 /usr/local/bin/

    method='["manage_wins_modules"]'
    ext_module="manage_aivax_install"
    cmd_category="aivax_install"
    command="aivax_install_util_module"
    detail_cmd="generate_version"

    # 버전 파일 실행, system python으로 수행되어야 한다.
    # license 정보, 우선 경로 파일을 읽거나, 기본값으로 할당한다.
    serial_key="SKRX4CWIS241299"
    license_key="af38d40897b5c174"
    # SERIAL_FILE="./SKRX4CWIS241299.crt"

    version_default_file=$(realpath "${g_path}/.version")
    serial_file=$(realpath "${g_path}/SKRX4CWIS241299.crt")

    json=$(jq -n \
        --argjson method "$method" \
        --arg ext_module "$ext_module" \
        --arg cmd_category "$cmd_category" \
        --arg command "$command" \
        --arg detail_cmd "$detail_cmd" \
        --arg serial_key "$serial_key" \
        --arg license_key "$license_key" \
        --arg serial_file "$serial_file" \
        --arg version_default_file "$version_default_file" \
        '{
            method:$method, 
            ext_module:$ext_module,
            cmd_category: $cmd_category,
            command: $command,
            detail_cmd: $detail_cmd,
            serial_key: $serial_key,
            license_key: $license_key,
            serial_file: $serial_file,
            version_default_file: $version_default_file
        }')

    # echo "${json}"

    cd .pyinstall/toolkit    
    # python aivax_toolkit.py --debug --printlog --script_config "${json}"
    python aivax_toolkit.py --script_config "${json}"
    cd - > /dev/null 2>&1

    # python version.py ${serial_key} ${license_key} ${SERIAL_FILE}

    # rm -rf .pyinstall

    # 라이선스 업로드 명령, management UI에 요청한다.
    # .ctr 파일, 복사 기능 필요, 일단 /tmp로 복사한다.

    # if [ -f "$SERIAL_FILE" ]; then
    #     cp -rf ${SERIAL_FILE} /tmp
    #     curl -fsSk -X POST 'https://127.0.0.1:4000/v1/internal/settings/license/upload' -H 'Content-Type: application/json' -d '{"licenseFilePath":"/tmp/SKRX4CWIS241299.crt"}' -o ./response.json 2>/dev/null
    # fi

    WRITE_LOG $FUNCNAME $LINENO "finish patch etc util"

}

function __setup_aivax_venv()
{

    WRITE_LOG $FUNCNAME $LINENO "start setup aivax venv"

    #TODO: python 경로는 고정으로.
    mkdir -p /home1/aivax

    # venv 생성, 여기서 python 버전은 세부 config로 제어
    # python3.13 -m venv /home1/aivax/aivax-venv
    # 설치시 기존에 존재하면 물어본다. 인스톨러에서는 옵션화
    # 존재하면 삭제 또는 넘어가기, 일단 기본으로 넘어간다.
    # uv venv /home1/aivax/aivax-venv
    VENV="/home1/aivax/aivax-venv"

    if [ ! -d "$VENV" ]; then
        # /usr/local/bin/uv venv --python /usr/local/bin/python3.13 --seed "$VENV"
        /usr/local/bin/uv venv --python /usr/local/bin/python3.13 "$VENV"
        \cp -rf /usr/local/bin/uv ${VENV}/bin/
    fi

    # \cp -rfv ./extension/python-install/uv .. 어디로 복사해야 하는지 모호, uv부분 다시 검증.

    #매번 재생성은 uv venv --clear 이다.

    # bash 추가, sed
    source /home1/aivax/aivax-venv/bin/activate

    #seed 대신 사용
    python -m ensurepip --default-pip

    #개선 필요
    # echo "source /home1/aivax/aivax-venv/bin/activate" >> /root/.bash_profile
    FILE="/root/.bash_profile"

    if ! grep -q "# >>> AIVAX VENV >>>" "$FILE"; then
cat << 'EOF' >> "$FILE"

# >>> AIVAX VENV >>>
source /home1/aivax/aivax-venv/bin/activate
# <<< AIVAX VENV <<<
EOF
fi

    cd ./extension/python-install

    # offlinewheel
    # TODO: aivax-requirement는, 패키지 빌드 과정에서 생성
    # cp -rf requirements.최신.txt aivax-requirement.txt
    # pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt
    uv --quiet pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt

    # pycomlib 설치, 버전 주의.
    #uv pip install pycom* --force-reinstall

    uv --quiet pip install ./offline-wheel/pycomlib-1.1.7-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pycomlibex-1.1.2-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pyservice-1.0.3-py3-none-any.whl --force-reinstall
    uv --quiet pip install ./offline-wheel/pytoolkit-1.0.0-py3-none-any.whl --force-reinstall

    # 이후 pipeline 이하 appserver 설치는 다음 스텝으로.
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

    #pip, venv 설정
    __setup_aivax_venv

    __patch_pipeline

    __patch_aivax_toolkit

    __patch_management

    __patch_sslproxy

    __patch_ai_engine

    # db migration 기능, management 수행후 처리
    __migrate_mariadb

    # 순서 이동, 제일 밑으로
    # __patch_etc_util

    WRITE_LOG $FUNCNAME $LINENO "finish patch aivax source"
}

function __patch_pipeline()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch pipeline"

    # pipeline 패치
    # apiserver도 같이 묶어서, 프로그램에서 세분화 + 공통화

    # 서비스 등록, 향후 프로그램으로 설치와 패치 분리

    tar xzf ./aivax-patch/pipeline.tar.gz 

    \mv -f pipeline /home1/aivax/

    #cp -rf aivax-pipeline.service /etc/systemd/system/
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

    #일단 압축만 해제, 기본 서비스를 어떻게 띄울지 미결정, 명령에 의해서 띄우는 쪽으로 
    #포트에 대한 이슈가 있을수 있다. api 호출은 필요시 기동

    systemctl daemon-reload
    systemctl enable aivax-toolkit
    systemctl start aivax-toolkit

    WRITE_LOG $FUNCNAME $LINENO "finish aivax toolkit"
}

function __patch_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch management"

    # management 패치

    # TODO: 빌드 스크립트에서 빌드된 manage 소스를 압축후 해제하는 정도로 마무리.

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

    # libpcap 설치, 우선 작성후 프로그램에서 모듈 분리
    # dnf install libpcap -y

    tar xzf ./aivax-patch/sslproxy.tar.gz 
    \mv -f sslproxy /home1/aivax/

    # 이건 테스트 하면서, 
    cp -rf ./extension/lib/libnet.so.1.8.0 /lib64/

    #TODO -f 주의
    ln -sf /lib64/libnet.so.1.8.0 /lib64/libnet.so.9

    ldconfig

    # network 설정
    # ip eth 정보를 알아야 한다. 프로그램으로 해결
    # 일단 경로는 설치하는데 초점

    # 지식재산처, 호출 주석 처리, 향후 installer에서 옵션화
    # ETH=$( ls /sys/class/net | grep -v '^lo$' | head -n 1)
    # bash /home1/aivax/sslproxy/network.sh ${ETH}

    cp -rf ./aivax-patch/systemd/sslproxy-install/aivax-sslproxy.service /etc/systemd/system/

    systemctl daemon-reload
    systemctl enable aivax-sslproxy.service
    systemctl start aivax-sslproxy


    #aivx_pro.sh를 실행해 본다. TODO: 경로, 향후 변경되어야 한다.
    # 잠시 주석 처리
    # cd /home1/aivax/sslproxy/etc_resource
    # chmod 755 aivx_pro.sh
    # echo 1 | ./aivx_pro.sh

    # cd - > /dev/null

    WRITE_LOG $FUNCNAME $LINENO "finish patch sslproxy"
}

function __migrate_mariadb()
{
    WRITE_LOG $FUNCNAME $LINENO "start migrate mariadb"

    #DB가 기동되고, aivax-management를 종료한 상태에서
    #node,npm을 설정하고, 명령을 실행한다.

    systemctl start mariadb
    systemctl stop aivax-management

    # mkdir -p /home1/aivax/extension/nodejs
    tar xf ./extension/nodejs-install/node-v24.11.1-linux-x64.tar 

    \mv node-v24.11.1-linux-x64 /home1/aivax/extension/nodejs

    # cp -rfv ./extension/nodejs-install/node-v24.11.1-linux-x64 /home1/aivax/extension/nodejs

    # cd /home1/aivax/toolkit

    # python aivax_toolkit.py --script_file /home1/aivax/toolkit/local_resource/script_config/aivax/rdb_backup.json

    # # #다시 원위치로.
    # cd ${g_path} > /dev/null

    cd /home1/aivax/management/backend 

    #path, 임시로 추가
    export PATH=/home1/aivax/extension/nodejs/bin:$PATH

    export NODE_ENV=production

    #TODO: 향후에는 drop 없이 migration만 수행한다. 26.03.25 지식재산처만 backup -> drop -> migration을 수행한다.    
    # /home1/aivax/extension/nodejs/bin/npm run db:backup > /dev/null #2>&1
    # /home1/aivax/extension/nodejs/bin/npm run db:drop > /dev/null #2>&1
    /home1/aivax/extension/nodejs/bin/npm run migration:run > /dev/null #2&>1

    cd - > /dev/null

    # 다시 복구 -> installer에서 제대로 개선
    # cd /home1/aivax/toolkit

    # python aivax_toolkit.py --script_file /home1/aivax/toolkit/local_resource/script_config/aivax/rdb_restore.json

    # cd - > /dev/null

    WRITE_LOG $FUNCNAME $LINENO "finish migrate mariadb"
}

####################################### service 등록 + 실행

function stop_aivax()
{
    WRITE_LOG $FUNCNAME $LINENO "stop aivax"

    # 재사용, 코드 정리는 installer에서 진행
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

    # systemctl stop fluent-bit
    # systemctl stop opensearch
    
    # systemctl stop mariadb

    # systemctl stop aivax-management
    # systemctl stop aivax-pipeline
    # systemctl stop aivax-toolkit

    # if systemctl is-active --quiet aivax-toolkit
    # then
    #     #systemctl stop myservice
    #     systemctl stop aivax-toolkit.service
    # fi
    
    # systemctl stop aivax-sslproxy

    # for i in 1 2 3 4
    # do
    #     if systemctl is-active --quiet ai-engine@$i
    #     then
    #         #systemctl stop myservice
    #         systemctl stop ai-engine@$i.service
    #     fi
    #     # systemctl stop ai-engine@$i.service
    # done

    #프로세스, 1개만 기동하도록 변경
    # systemctl stop ai-engine.service

    WRITE_LOG $FUNCNAME $LINENO "finish stop aivax"
}

function start_aivax()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax"

    # systemctl daemon-reexec
    systemctl daemon-reload

    # systemctl is-enabled nginx 로 미리 점검, installer에서 변경

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

    # 프로세스 1개만 기동
    # for i in 1 2 3 4; do        
    #     systemctl start ai-engine@$i.service
    # done

    # systemctl start ai-engine@1.service
    systemctl start ai-engine.service

    WRITE_LOG $FUNCNAME $LINENO "finish start aivax"
}

# 설치 완료후 설정 작업
function configure_after_install()
{
    WRITE_LOG $FUNCNAME $LINENO "start configure after install"

    # opensearch, 기동시까지 대기한다.
    # 무한루프를 돌면 안되기 때문에, 5번만 loop => 수정 필요
    # until curl -u admin:'Sniper123!@#' -sk https://127.0.0.1:9200/_cluster/health| grep -q '"status"'; do
    #     sleep 2
    # done

    #TODO: 상세한 예외처리는 installer에서
    wait_ready_opensearch

    #opensearch, 부가 index의 삭제, 초기화
    # 향후 계정, 포트 등 접속 정보는 installer에서 제거
    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/top_queries-*"     
    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/security-auditlog-*" 

    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/aivax_log_reindexed_*"

    # template의 삭제 
    curl -u admin:'Sniper123!@#' -sk -XDELETE "https://127.0.0.1:9200/_index_template/query_insights_top_queries_template" 

    # index 목록의 조회
    curl -u admin:'Sniper123!@#' -sk https://127.0.0.1:9200/_cat/indices?v

    # 라이선스 업데이트, 제일 밑으로
    __update_serial_license

    WRITE_LOG $FUNCNAME $LINENO "finish configure after install"

}

function wait_ready_opensearch()
{

    WRITE_LOG $FUNCNAME $LINENO "wait ready opensearch"

    local RETRY=5
    local COUNT=0

    # echo "waiting for opensearch..."

    while [ $COUNT -lt $RETRY ]
    do
        # cluster health 확인
        RESPONSE=$(curl -sk -u admin:'Sniper123!@#' https://127.0.0.1:9200/_cluster/health)

        # 정상 응답 여부 확인
        echo "$RESPONSE" | grep -q '"status"'

        if [ $? -eq 0 ]; then
            # echo "opensearch ready"            
            return 0
        fi

        COUNT=$((COUNT+1))

        echo "not ready yet... retry ${COUNT}/${RETRY}"
        WRITE_LOG $FUNCNAME $LINENO "wait start opensearch (${COUNT}/${RETRY})"

        sleep 2
    done

    # echo "opensearch ready timeout"
    return 1
}

function clear_install_resource()
{

    # cd .pyinstall/toolkit
    rm -rf .pyinstall

    #venv 종료
    deactivate
}

####################################### main, 실행

function main()
{

    install_default_modules

    ui_interface

    # TODO: 경로를 생성해야 한다. 경로가 제일 먼저이다.
    init_default_setup

    #패치전, 서비스를 내린다. 향후 개선
    stop_aivax

    # 최초, 모듈 설치
    install_module

    # 외부 오픈소스 실행
    # build_install_slm

    # 소스 패치
    patch_aivax_source

    # 프로세스 기동
    start_aivax

    # 시작후 부가작업 (opensearch 외)
    configure_after_install

    # 최종 자원 정리, 우선 제외
    # clear_install_resource

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