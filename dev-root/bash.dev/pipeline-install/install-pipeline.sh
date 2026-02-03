
g_path=$( cd "$(dirname "$0")" ; pwd )

source ${g_path}/global.sh

function install_rpm()
{
    WRITE_LOG $FUNCNAME $LINENO "install rpm"

    #createrepo 설치
    #cd extension/rpm-install/core-rpm/createrepo

    #TODO: 두번 설치 테스트 필요
    rpm -ivh extension/rpm-install/core-rpm/createrepo/createrepo_c-libs-0.20.1-4.el9.x86_64.rpm 
    rpm -ivh extension/rpm-install/core-rpm/createrepo/createrepo_c-0.20.1-4.el9.x86_64.rpm
    #cd -

    mkdir -p /home1/aivax/extension/rpm
    mkdir -p /home1/aivax/extension/rpm/3rd-repo/mariadb

    \cp -rf extension/rpm-install/base-repo /home1/aivax/extension/rpm/
    \cp -rf extension/rpm-install/extra-repo /home1/aivax/extension/rpm/

    \cp -rf extension/rpm-install/3rd-repo/mariadb/v11.3.2 /home1/aivax/extension/rpm/3rd-repo/mariadb/
    \cp -rf extension/rpm-install/3rd-repo/libreoffice/office-headless /home1/aivax/extension/rpm/3rd-repo/

    #createrepo 업데이트
    createrepo /home1/aivax/extension/rpm/base-repo/
    createrepo /home1/aivax/extension/rpm/extra-repo/

    createrepo /home1/aivax/extension/rpm/3rd-repo/mariadb/v11.3.2/
    createrepo /home1/aivax/extension/rpm/3rd-repo/office-headless/

    \cp -f extension/rpm-install/core-rpm/repos.d/aivax.repo /etc/yum.repos.d/

    dnf clean all
    dnf makecache

    dnf install --disablerepo="*" --enablerepo="aivax-repo" libreoffice-headless -y
    dnf install --disablerepo="*" --enablerepo="aivax-repo" tesseract -y
    dnf install --disablerepo="*" --enablerepo="aivax-repo" tesseract-langpack-kor -y
}

function install_python_pip()
{
    WRITE_LOG $FUNCNAME $LINENO "install python pip"

    # uv 복사
    \cp -f extension/python-install/uv /usr/local/bin/

    # pip 재설치
    uv pip install --no-index --find-links=./offline-wheel/ -r aivax-requirement.txt

    # service 재설치
    uv pip install pycomlib-1.1.2-py3-none-any.whl --force-reinstall
    uv pip install pycomlibex-1.0.7-py3-none-any.whl --force-reinstall
    uv pip install pyservice-1.0.2-py3-none-any.whl --force-reinstall
}

function patch_pipeline()
{
    WRITE_LOG $FUNCNAME $LINENO "patch pipeline"

    \mv -f /home1/aivax/pipeline /home1/aivax/pipeline.old.20260204

    cp -rf aivax-patch/pipeline /home1/aivax/

    systemctl restart aivax-pipeline
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
    'https://10.0.240.150:4000/openapi/v1/filter/multiple_filter' \
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
    WRITE_LOG $FUNCNAME $LINENO "start install pipeline"


    # rpm 설치
    install_rpm

    install_python_pip

    patch_pipeline

    aivax_status

}

main $@