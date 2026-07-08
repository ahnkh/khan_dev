
g_path=$( cd "$(dirname "$0")" ; pwd )

TRACE_LOG="./tracelog.txt"

git_root=/data/git-root
package_root=/data/data-root/aivax-install-root/aivax-install

aivax_ver=v1.0.0.1

aivax_package_release_root="/data/data-root/aivax-install-root"

git_branch="qa_release"

target_server="10.0.240.150"

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

function merge_git()
{
    WRITE_LOG $FUNCNAME $LINENO "start merge git"

    cd ${git_root}/aivax/apps/

    git pull
    git switch ${git_branch}

    git merge origin/develop --no-edit
    # git merge origin/develop

    git push

    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish merge git"
}

function build_management()
{
    WRITE_LOG $FUNCNAME $LINENO "start build management"

    cd ${git_root}/aivax/apps/management

    git switch ${git_branch}

    # git checkout frontend/package-lock.json
    # git checkout backend/package-lock.json

    git pull

    cd backend
    
    npm run build
    npm install

    cd ../frontend

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

    cd ${git_root}/aivax/pipeline

    git switch ${git_branch}

    git pull

    cd ${git_root}/aivax

    tar -czf pipeline.tar.gz --exclude='.git' --exclude='.gitignore' --exclude='.vscode' pipeline/

    mv pipeline.tar.gz ${package_root}/aivax-patch/

    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish build pipeline"
}

function git_patch_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "start patch sslproxy"

    mkdir -p ${git_root}/aivax/sslproxy_temp_repo
    mkdir -p ${git_root}/aivax/sslproxy

    scp -P222 -r root@${target_server}:/backup/repository ${git_root}/aivax/sslproxy_temp_repo/

    \cp -rfv ${git_root}/aivax/sslproxy_temp_repo/repository/sslproxy ${git_root}/aivax/sslproxy/
    \cp -rfv ${git_root}/aivax/sslproxy_temp_repo/repository/sslproxy.conf ${git_root}/aivax/sslproxy/
    \cp -rfv ${git_root}/aivax/sslproxy_temp_repo/repository/Note.md ${git_root}/aivax/sslproxy/.note.md

    find ${git_root}/aivax/sslproxy_temp_repo/repository/ai_engine | grep __pycache__ | xargs -i rm -rf {}
    \cp -rfv ${git_root}/aivax/sslproxy_temp_repo/repository/ai_engine/* ${git_root}/aivax/aivax-package/ai_engine/

    WRITE_LOG $FUNCNAME $LINENO "finish patch sslproxy"
}

#sslproxy도 별도 git으로 관리
function build_sslproxy()
{
    WRITE_LOG $FUNCNAME $LINENO "start build sslproxy"

    cd ${git_root}/aivax/

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

function make_version_text_file()
{

    WRITE_LOG $FUNCNAME $LINENO "start make version text file"

    AIVAX_DIR="${git_root}/aivax"

    AIVAX_TAG=$(git -C ${git_root}/aivax describe --tags --abbrev=0 2>/dev/null)
    AIVAX_HASH=$(git -C ${git_root}/aivax rev-parse --short HEAD 2>/dev/null)

    #sslproxy hash
    ENGINE_FILE="${git_root}/aivax/sslproxy"

    FILE_HASH=$(sha256sum "$ENGINE_FILE" | awk '{print $1}')
    ENGINE_HASH_SHORT=${FILE_HASH:0:7}

    AIVAX_TITLE_VERSION=${AIVAX_TAG//_/ }

    WRITE_LOG $FUNCNAME $LINENO "TITLE VERSION = ${AIVAX_TITLE_VERSION}"

    WRITE_LOG $FUNCNAME $LINENO "AIVAX HASH = ${AIVAX_HASH}"
    WRITE_LOG $FUNCNAME $LINENO "ENGINE HASH = ${ENGINE_HASH_SHORT}"

    VERSION_FILE="${package_root}/.version"

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

    package_date=$(date +%Y%m%d)

    cd ${aivax_package_release_root}

    cp -rf aivax-install/install.sh aivax-install/aivax-patch/install-temp

    hash=$(tar -cf - aivax-install/aivax-patch/ | sha256sum | awk '{print $1}' | cut -c1-6)

    rm -rf aivax-install/aivax-patch/install-temp

    aivax_package_file=aivax-install.${aivax_ver}.$package_date.${hash}

    cp -rf aivax-install ${aivax_package_file}

    tar -czf ${aivax_package_file}.tar.gz ${aivax_package_file}

    rm -rf ${aivax_package_file}

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

    git_patch_sslproxy

    build_sslproxy
    build_ai_engine

    make_version_text_file

    release_package

    WRITE_LOG $FUNCNAME $LINENO "finish aivax build"
}

main $@