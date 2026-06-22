
g_path=$( cd "$(dirname "$0")" ; pwd )

git_root=/home1/git-root

function WRITE_LOG()
{

    GREEN='\033[1;32m'
    NC='\033[0m' # No Color

    bold=$(tput bold)
    normal=$(tput sgr0)

    local string="[$(date '+%Y/%m/%d %H:%M:%S')][$$][$1:($2)] $3 $4"
        
    echo -e "${GREEN}[$(date '+%Y/%m/%d %H:%M:%S')]${NC}${bold} $3 ${normal}"
    
    # echo $string &>> ${g_path}/${TRACE_LOG}
    
}

# pipeline, source merge
function merge_pipeline_git()
{
    # git_root=/home1/git-root
    WRITE_LOG $FUNCNAME $LINENO "start merge pipeline git source"

    cd ${git_root}/aivax_pipelines_public

    git remote -v

    git pull

    # 과거 소스, 정리
    cd ${git_root}/aivax_pipeline/

    git remote -v

    rm -rf pipeline.old

    mv pipeline pipeline.old

    # cd ${git_root}/

    # 현재 소스, 이동
    cp -rfv ${git_root}/aivax_pipelines_public ${git_root}/aivax_pipeline/
    mv ${git_root}/aivax_pipeline/aivax_pipelines_public ${git_root}/aivax_pipeline/pipeline

    # git 소스 제거
    rm -rf ${git_root}/aivax_pipeline/pipeline/.git
    rm -rf ${git_root}/aivax_pipeline/pipeline/.vscode
    rm -rfv ${git_root}/aivax_pipeline/pipeline/.TEMP

    find ${git_root}/aivax_pipeline/pipeline | grep __pycache__ | xargs -i rm -rf {}

    cd ${git_root}/aivax_pipeline/pipeline

    git status

    git add .

    git status

    git commit -m "pipeline commit $(date '+%Y-%m-%d %H:%M:%S')"

    git push

    WRITE_LOG $FUNCNAME $LINENO "finish merge pipeline git source"
}

# develop branch, merge 한다.
function merge_to_develop()
{
    # git_root=/home1/git-root

    WRITE_LOG $FUNCNAME $LINENO "start merge pipeline aivax pipeline to develop"

    cd ${git_root}

    # 너무 오래 걸린다.
    if [ -z develop ]
    then

        rm -rf develop
        git clone -b develop git@github.com:winstechnet/aivax.git develop

    fi

    cd develop

    git pull

    git merge origin/aivax_pipeline

    git push
}



function main()
{

    # aivax_pipelines_public -> aivax_pipeline으로 merge
    merge_pipeline_git

    # aivax_pipeline -> develop 으로 merge (기본 develop 브랜치 삭제, 깨끗한 환경에서 merge)
    merge_to_develop
}


main $@