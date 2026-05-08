
g_path=$( cd "$(dirname "$0")" ; pwd )

# source ${g_path}/patch.sh

TRACE_LOG="./tracelog.txt"

git_root=/data/git-root
package_root=/data/data-root/aivax-install-root/aivax-install

# 패키지 명칭에 추가할 버전, 대소문자 등 관리 불편으로 git대신 하드코딩
#향후 개선.
aivax_ver=v1.0.0.0

aivax_package_release_root="/data/data-root/aivax-install-root"

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

# management build, 이동
# TODO: 경로등에 대해서는 installer, aivax-builder에서 개선
function build_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start build management"

    cd ${git_root}/aivax/apps/management

    git checkout frontend/package-lock.json
    git checkout backend/package-lock.json

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

#version 파일 생성
function make_version_text_file()
{

    WRITE_LOG $FUNCNAME $LINENO "start make version text file"

    AIVAX_DIR="${git_root}/aivax"
    PIPELINE_DIR="${git_root}/pipeline"

    AIVAX_TAG=$(git -C ${git_root}/aivax describe --tags --abbrev=0 2>/dev/null)
    AIVAX_HASH=$(git -C ${git_root}/aivax rev-parse --short HEAD 2>/dev/null)

    #AIVAX VERSION
    AIVAX_TITLE_VERSION=${AIVAX_TAG//_/ }

    # PIPELINE_TAG=$(git -C "$PIPELINE_DIR" describe --tags --abbrev=0 2>/dev/null)
    PIPELINE_HASH=$(git -C "$PIPELINE_DIR" rev-parse --short HEAD 2>/dev/null)

    WRITE_LOG $FUNCNAME $LINENO "TITLE VERSION = ${AIVAX_TITLE_VERSION}"

    WRITE_LOG $FUNCNAME $LINENO "AIVAX HASH = ${AIVAX_HASH}"
    WRITE_LOG $FUNCNAME $LINENO "ENGINE HASH = ${PIPELINE_HASH}"

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
${PIPELINE_HASH}
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
    cp -rfv aivax-install/install.sh aivax-install/aivax-patch/install-temp

    hash=$(tar -cf - aivax-install/aivax-patch/ | sha256sum | awk '{print $1}' | cut -c1-6)

    #패키지를 만들기전, 임시파일 삭제
    rm -rf aivax-install/aivax-patch/install-temp

    aivax_package_file=aivax-install.${aivax_ver}.$package_date.${hash}

    cp -rfv aivax-install ${aivax_package_file}

    tar -czf ${aivax_package_file}.tar.gz ${aivax_package_file}

    # #마지막. 날짜뒤에 hash 추가 => TODO: hash 전략 필요, hash로 git정보를 알수 있어야 한다.
    # #version 파일을 생성 => aivax, pipeline, sslproxy 3개 조합의 파일
    # file="aivax-install.${aivax_ver}.$today.tar.gz"

    # new_file="aivax-install.${aivax_ver}.$today.${hash}.tar.gz"

    # # 파일 이름 변경
    # mv "$file" "$new_file"

    #마지막, 임시파일 삭제
    rm -rf ${aivax_package_file}

    WRITE_LOG $FUNCNAME $LINENO "finish release package"
}


function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start aivax build"

    build_management

    build_pipeline

    build_toolkit

    update_install_script

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