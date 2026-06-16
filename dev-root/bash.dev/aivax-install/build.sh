
g_path=$( cd "$(dirname "$0")" ; pwd )

# source ${g_path}/patch.sh

TRACE_LOG="./tracelog.txt"

git_root=/data/git-root
package_root=/data/data-root/aivax-install-root/aivax-install

# 패키지 명칭에 추가할 버전, 대소문자 등 관리 불편으로 git대신 하드코딩
#향후 개선.
aivax_ver=v1.0.0.0

aivax_package_release_root="/data/data-root/aivax-install-root"

#TODO: 환경변수로.
# git_branch="develop"
git_branch="qa_release"

# 버전정보, git의 tag에서 가져온다.
# GIT_TAG=$(git describe --tags --abbrev=0)
# DISPLAY_VERSION=${GIT_TAG//_/ }
# echo "$DISPLAY_VERSION"
# AIVAX_VERSION="SNIPER AIVAX V1.0.0.0"

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

#git merge, 이건 보면서 하자.
function merge_git()
{
    WRITE_LOG $FUNCNAME $LINENO "start merge git"

    cd ${git_root}/aivax/apps/

    git pull
    git switch ${git_branch}

    # git merge origin/develop --no-edit
    git merge origin/develop

    git push

    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish merge git"
}

# management build, 이동
# TODO: 경로등에 대해서는 installer, aivax-builder에서 개선
function build_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start build management"

    #TOOD: 경로, 지정된 경로.
    cd ${git_root}/aivax/apps/management

    # branch 선택, 나머지는 같다.
    git switch ${git_branch}

    #불필요 파일, checkout
    git checkout frontend/package-lock.json
    git checkout backend/package-lock.json

    git pull

    #back end
    cd backend

    npm i #신규 모듈이 추가되면 인터넷 다운로드
    npm run build
    npm install

    # frontend
    cd ../frontend

    npm i #신규 모듈이 추가되면 인터넷 다운로드
    npm run build
    npm install

    cd ${git_root}/aivax/apps

    tar -czf management.tar.gz --exclude='.git' --exclude='.gitignore' --exclude='.vscode' --exclude='.cursor' management/

    mv management.tar.gz ${package_root}/aivax-patch/
    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish build management"
}

function build_pipeline()
{
    WRITE_LOG $FUNCNAME $LINENO "start build pipeline"

    # cd ${git_root}/pipeline
    cd ${git_root}/aivax/pipeline

    # branch 선택, 독립적, 한번 더 수행.
    git switch ${git_branch}

    git pull

    cd ${git_root}/aivax

    tar -czf pipeline.tar.gz --exclude='.git' --exclude='.gitignore' --exclude='.vscode' pipeline/

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

#sslproxy, 자동 다운로드 및 git commit
function git_patch_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch sslproxy"

    mkdir -p ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo

    scp -P222 -r root@10.0.240.150:/backup/repository ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo/

    #TODO: 하나씩 이동, sslproxy
    # cp -rfv ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo/repository/* ${git_root}/aivax_public/aivax-package/sslproxy/
    \cp -rfv ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo/repository/sslproxy ${git_root}/aivax_public/aivax-package/sslproxy/
    \cp -rfv ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo/repository/Note.md ${git_root}/aivax_public/aivax-package/sslproxy/.note.md

    # python 모듈 이동, ai_engine
    # __pycache__는 지워야 한다.
    find ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo/repository/ai_engine | grep __pycache__ | xargs -i rm -rf {}
    \cp -rfv ${git_root}/aivax_public/aivax-package/sslproxy_temp_repo/repository/ai_engine/* ${git_root}/aivax_public/aivax-package/ai_engine/

    cd ${git_root}/aivax_public/
    git add ${git_root}/aivax_public/aivax-package/sslproxy/
    git commit -m "sslproxy update $(date '+%Y-%m-%d %H:%M:%S')"

    git add ${git_root}/aivax_public/aivax-package/ai_engine/
    git commit -m "ai_engine update $(date '+%Y-%m-%d %H:%M:%S')"

    git push 

    cd -

#     /backup/repository ~$ tree
# .
# ├── ai_engine
# │   ├── account_lookup.py
# │   ├── adapter_registry.py
# │   ├── adapters
# │   │   ├── __init__.py
# │   │   ├── adapter_template.py
# │   │   ├── chatgpt_engine.py
# │   │   ├── claude_engine.py
# │   │   ├── gemini_engine.py
# │   │   ├── grok_engine.py
# │   │   ├── notion_engine.py
# │   │   ├── perplexity_engine.py
# │   │   └── wrks_engine.py
# │   ├── ai_policy_engine.md
# │   ├── ai_policy_engine.py
# │   ├── ai_service_codes.py
# │   ├── file_upload_manager.py
# │   └── run_engine.sh
# └── sslproxy

    #이걸 어떻게 반영할지는 검토후 결정

    WRITE_LOG $FUNCNAME $LINENO "finish patch sslproxy"
}

#sslproxy도 별도 git으로 관리
function build_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "start build sslproxy"

    cd ${git_root}/aivax_public/aivax-package/

    git pull

    tar -czf sslproxy.tar.gz --exclude='.git' --exclude='.gitignore' sslproxy/

    mv sslproxy.tar.gz ${package_root}/aivax-patch/

    WRITE_LOG $FUNCNAME $LINENO "finish build sslproxy"
    
}

function build_ai_engine()
{
    WRITE_LOG $FUNCNAME $LINENO "start build ai_engine"

    git pull

    tar -czf ai_engine.tar.gz --exclude='.git' --exclude='.gitignore' ai_engine/

    mv ai_engine.tar.gz ${package_root}/aivax-patch/

    WRITE_LOG $FUNCNAME $LINENO "finish build ai_engine"
}

function update_install_script()
{
    WRITE_LOG $FUNCNAME $LINENO "start update install script"

    cd ${git_root}/khan_dev/dev-root/bash.dev/aivax-install

    cp -rfv install.sh ${package_root}/

    WRITE_LOG $FUNCNAME $LINENO "finish update install script"
}

function update_pycomlib()
{

    WRITE_LOG $FUNCNAME $LINENO "start update pycom lib"

    # git_root=/data/git-root
    # package_root=/data/data-root/aivax-install-root/aivax-install

    cd ${git_root}/khan.pythonscript/
    svn update --username khan --password '1111' --non-interactive

    cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pycomlib-1.1.7-py3-none-any.whl ${package_root}/extension/python-install/offline-wheel/
    cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pycomlibex-1.1.2-py3-none-any.whl ${package_root}/extension/python-install/offline-wheel/

    cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pyservice-1.0.3-py3-none-any.whl ${package_root}/extension/python-install/offline-wheel/
    cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/pytoolkit-1.0.0-py3-none-any.whl ${package_root}/extension/python-install/offline-wheel/

    cd -

    WRITE_LOG $FUNCNAME $LINENO "finish update pycom lib"
}

#version 파일 생성
function make_version_text_file()
{

    WRITE_LOG $FUNCNAME $LINENO "start make version text file"

    AIVAX_DIR="${git_root}/aivax"

    #TODO: engine 버전은 실제 sslproxy 데몬의 hash로.
    # PIPELINE_DIR="${git_root}/sslproxy"

    AIVAX_TAG=$(git -C ${git_root}/aivax describe --tags --abbrev=0 2>/dev/null)
    AIVAX_HASH=$(git -C ${git_root}/aivax rev-parse --short HEAD 2>/dev/null)

    #sslproxy hash
    ENGINE_FILE="${git_root}/aivax_public/aivax-package/sslproxy/sslproxy"

    FILE_HASH=$(sha256sum "$ENGINE_FILE" | awk '{print $1}')
    ENGINE_HASH_SHORT=${FILE_HASH:0:7}

    #AIVAX VERSION
    AIVAX_TITLE_VERSION=${AIVAX_TAG//_/ }

    # PIPELINE_TAG=$(git -C "$PIPELINE_DIR" describe --tags --abbrev=0 2>/dev/null)
    # PIPELINE_HASH=$(git -C "$PIPELINE_DIR" rev-parse --short HEAD 2>/dev/null)

    WRITE_LOG $FUNCNAME $LINENO "TITLE VERSION = ${AIVAX_TITLE_VERSION}"

    WRITE_LOG $FUNCNAME $LINENO "AIVAX HASH = ${AIVAX_HASH}"
    # WRITE_LOG $FUNCNAME $LINENO "ENGINE HASH = ${PIPELINE_HASH}"
    WRITE_LOG $FUNCNAME $LINENO "ENGINE HASH = ${ENGINE_HASH_SHORT}"

    # echo "AIVAX    : ${AIVAX_TAG} ${AIVAX_HASH}"
    # echo "PIPELINE : ${PIPELINE_TAG}-${PIPELINE_HASH}"

# SNIPER AIVAX V1.0.0.0
# 1b852b76
# 6144c68

    VERSION_FILE="${package_root}/.version"

    # version.txt 생성
cat > "$VERSION_FILE" <<EOF
${AIVAX_TITLE_VERSION}
${AIVAX_HASH}
${ENGINE_HASH_SHORT}
EOF

    WRITE_LOG $FUNCNAME $LINENO "finish make version text file"
}

function release_package()
{

    WRITE_LOG $FUNCNAME $LINENO "start release package"
    
    # 과거 패키지, 유지하고 향후 별도 스케쥴러에서 삭제하도록 변경
    #rm -rf aivax-install.v1.0.1.$(date +%Y%m%d).tar.gz

    # package_date=$(date +%Y%m%d%H%M)
    package_date=$(date +%Y%m%d)
    # today=$(date +%Y%m%d)

    # aivax_ver=v1.0.0.0

    # aivax_package_root="/data/data-root/aivax-install-root"

    cd ${aivax_package_release_root}

    #임시 방편, 우선 현재 파일의 hash를 구분할수 있도록 설정한다.
    #aivax의 패치 형상을 기준으로 hash를 만든다.

    #install.sh가 변경시에도 hash를 만들도록 임시 추가, 향후 git의 hash로 처리되어야 한다.
    cp -rf aivax-install/install.sh aivax-install/aivax-patch/install-temp

    hash=$(tar -cf - aivax-install/aivax-patch/ | sha256sum | awk '{print $1}' | cut -c1-6)

    #패키지를 만들기전, 임시파일 삭제
    rm -rf aivax-install/aivax-patch/install-temp

    aivax_package_file=aivax-install.${aivax_ver}.$package_date.${hash}

    cp -rf aivax-install ${aivax_package_file}

    tar -czf ${aivax_package_file}.tar.gz ${aivax_package_file}

    # #마지막. 날짜뒤에 hash 추가 => TODO: hash 전략 필요, hash로 git정보를 알수 있어야 한다.
    # #version 파일을 생성 => aivax, pipeline, sslproxy 3개 조합의 파일
    # file="aivax-install.${aivax_ver}.$today.tar.gz"

    # new_file="aivax-install.${aivax_ver}.$today.${hash}.tar.gz"

    # # 파일 이름 변경
    # mv "$file" "$new_file"

    #마지막, 임시파일 삭제
    rm -rf ${aivax_package_file}

    #패키지, 임시 경로로 이동
    mv ${aivax_package_file}.tar.gz temp-release/

    find temp-release/ -maxdepth 1 -type f -printf '%T@ %p\n' | sort -nr | tail -n +6 | cut -d' ' -f2- | xargs -r rm -f

    WRITE_LOG $FUNCNAME $LINENO "finish release package"
}


function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax build"

    merge_git

    build_management

    build_pipeline

    build_toolkit

    git_patch_sslproxy

    build_sslproxy
    build_ai_engine

    # 설치 스크립트, 향후 변경
    update_install_script

    #pycomlib 업데이트
    update_pycomlib

    #버전 파일 생성
    make_version_text_file

    #패치 실행
    #patch.sh => 하나로 통합
    release_package

    #자동업로드 기능 추가
    cd /data/data-root/aivax-install-root/
    bash auto-install.sh

    WRITE_LOG $FUNCNAME $LINENO "finish aivax build"
}

main $@