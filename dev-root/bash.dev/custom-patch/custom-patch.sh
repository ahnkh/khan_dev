
g_path=$( cd "$(dirname "$0")" ; pwd )

source ${g_path}/global.sh

function install_rpm()
{
    WRITE_LOG $FUNCNAME $LINENO "install rpm"

    #createrepo 설치
    #cd extension/rpm-install/core-rpm/createrepo

    # repo 업데이트, 기본 비활성화
    \cp -f extension/rpm-install/aivax.repo /etc/yum.repos.d/

    #TODO: 두번 설치 테스트 필요
    rpm -ivh extension/rpm-install/createrepo/createrepo_c-libs-0.20.1-4.el9.x86_64.rpm 
    rpm -ivh extension/rpm-install/createrepo/createrepo_c-0.20.1-4.el9.x86_64.rpm
    #cd -

    # mkdir -p /home1/aivax/extension/rpm
    # mkdir -p /home1/aivax/extension/rpm/3rd-repo/mariadb
    mkdir -p /home1/install/extension/rpm-repo/

    # \cp -rf extension/rpm-install/base-repo /home1/aivax/extension/rpm/
    # \cp -rf extension/rpm-install/extra-repo /home1/aivax/extension/rpm/

    # #\cp -rfv extension/rpm-install/3rd-repo/mariadb/v11.3.2 /home1/aivax/extension/rpm/3rd-repo/mariadb/
    # \cp -rf extension/rpm-install/3rd-repo/libreoffice/office-headless /home1/aivax/extension/rpm/3rd-repo/

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


    createrepo /home1/install/extension/rpm-repo/

    dnf clean all
    dnf makecache

    # dnf install --disablerepo="*" --enablerepo="aivax-office" libreoffice-headless -y
    # dnf install --disablerepo="*" --enablerepo="local-aivax" tesseract -y
    # dnf install --disablerepo="*" --enablerepo="local-aivax" tesseract-langpack-kor -y

    dnf install jq --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install tree --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install sqlite --disablerepo="*" --enablerepo="aivax-repo" -y

    # file 추출, OCR 관련
    dnf install libreoffice-headless --disablerepo="*" --enablerepo="aivax-repo" -y

    dnf install tesseract --disablerepo="*" --enablerepo="aivax-repo" -y 

    dnf install tesseract-langpack-kor --disablerepo="*" --enablerepo="aivax-repo" -y 

    # #maridb 설치
    # dnf install MariaDB-server MariaDB-client --disablerepo="*" --enablerepo="aivax-repo" -y

    # dnf install nginx --disablerepo="*" --enablerepo="aivax-repo" -y
}

function install_python_pip()
{
    WRITE_LOG $FUNCNAME $LINENO "install python pip"

    # uv 복사
    \cp -f extension/python-install/uv /usr/local/bin/

    #기존 설치된 venv는 백업후, 새로 만들자. uv가 만든게 아니면
    # 지식재산처 임시, 최초 패키지는 처음부터 uv로 만든다.
    source /home1/aivax/aivax-venv/bin/activate

    # mv /home1/aivax/aivax-venv /home1/aivax/aivax-venv.pip
    # uv venv 

    # pip 재설치
    uv pip install --no-index --find-links=./extension/python-install/offline-wheel/ -r ./extension/python-install/aivax-requirement.txt --system

    # service 재설치
    uv pip install ./extension/python-install/pycomlib-1.1.2-py3-none-any.whl --force-reinstall --system
    uv pip install ./extension/python-install/pycomlibex-1.0.7-py3-none-any.whl --force-reinstall --system
    uv pip install ./extension/python-install/pyservice-1.0.2-py3-none-any.whl --force-reinstall --system

}

function patch_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "patch sslproxy"

    #기존에 존재하면 삭제
    #TODO: 최종버전에서는 /home1/aivax.old.[날짜] 생성, 프로그래밍
    rm -rf /home1/aivax/sslprox.old
    \mv -f /home1/aivax/sslproxy /home1/aivax/sslproxy.old

    #현재 경로에 압축해제, 이후 이동
    tar xzvf aivax-patch/sslproxy.tar.gz 

    \mv sslproxy /home1/aivax/

    systemctl restart aivax-sslproxy
}

function patch_pipeline()
{
    WRITE_LOG $FUNCNAME $LINENO "patch pipeline"

    #기존에 존재하면 삭제
    rm -rf /home1/aivax/pipeline.old.20260204
    \mv -f /home1/aivax/pipeline /home1/aivax/pipeline.old.20260204

    # \cp -rf aivax-patch/pipeline /home1/aivax/
    tar xzvf aivax-patch/pipeline.tar.gz 

    \mv pipeline /home1/aivax/

    systemctl restart aivax-pipeline
}

function patch_management()
{
    WRITE_LOG $FUNCNAME $LINENO "patch management"

    #기존에 존재하면 삭제
    rm -rf /home1/aivax/management.old
    \mv -f /home1/aivax/management /home1/aivax/management.old

    # \cp -rf aivax-patch/pipeline /home1/aivax/
    tar xzvf aivax-patch/management.tar.gz

    \mv management /home1/aivax/

    systemctl restart aivax-management
}

function aivax_status()
{
    WRITE_LOG $FUNCNAME $LINENO "aivax status"

    # aivax 포트 상태 확인 
    # 4000 (management), 9099 (pipeline), 3001 (node), 9200 (opensearch)

    WRITE_LOG $FUNCNAME $LINENO "aivax port status"
    ss -natup | egrep ":4000|:9099|3001|9200"

    # service 상태 확인
    # mariadb, opensearch, pipeline, management, sslproxy

    WRITE_LOG $FUNCNAME $LINENO "aivax service status"

    systemctl status mariadb | head -15
    systemctl status opensearch | head -15
    systemctl status fluent-bit | head -15
    systemctl status nginx | head -15

    systemctl status aivax-pipeline | head -15
    systemctl status aivax-management | head -15    
    systemctl status aivax-sslproxy | head -15

    # 프로세스 정보 출력

    # curl, pipeline 테스트 코드 호출 (지식재산처 전용, 향후에는 제거)
    curl -sk -X 'POST' \
    'http://127.0.0.1:9099/v1/filter/multiple_filter' \
    -H 'accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '{
    "filter_list": [
        "input_filter",
        "secret_filter",
        "slm_filter"
    ],
    "prompt": "동작 테스트",
    "encoding": false,
    "user_id": "",
    "email": "",
    "ai_service": 0,
    "client_host": "",
    "session_id": "",
    "attachments": [
        {
        "id": "",
        "size": 0,
        "name": "",
        "mime_type": ""
        }
    ],
    "message_id": ""
    }'

    # curl, opensearch 호출
    curl -u admin:'Sniper123!@#' -sk https://127.0.0.1:9200/_cat/indices?v

}


function main()
{
    WRITE_LOG $FUNCNAME $LINENO "patch install aivax"

    # rpm 설치
    install_rpm

    install_python_pip

    patch_pipeline

    patch_management

    patch_sslproxy

    # aivax_status

    WRITE_LOG $FUNCNAME $LINENO "finish patch aivax"

}

main $@