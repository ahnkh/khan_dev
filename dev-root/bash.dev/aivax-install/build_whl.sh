
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

function update_toolkit_whl_module()
{
    WRITE_LOG $FUNCNAME $LINENO "start update toolkit whl module"

    # ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/

    # svn 업데이트, svn commit 보다는 신규 생성쪽으로
    mkdir -p ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/

    cd ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/
    svn update --username khan --password '1111' --non-interactive

    # python temp dir 경로의 whl 정리
    rm -rfv ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/operation_util_manage_modules
    rm -rfv ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/wins_manage_modules

    rm -rfv ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/dist/*

    # toolkit 소스 업데이트, 복사
    cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/util_modules/operation_util_manage_modules ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/
    cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/util_modules/wins_manage_modules ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/

    # python build
    # cd ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/

    #ubuntu는 python3
    python -m build

    unzip -l dist/pytoolkit-1.0.0-py3-none-any.whl | head -100

    #uv 테스트
    uv pip install --force-reinstall dist/pytoolkit-1.0.0-py3-none-any.whl

    # build 결과물 업데이트 및 소스 commit
    # TODO: 오타가 있다. build_ouput -> build_output 점진적으로 고치자.
    cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/dist/pytoolkit-1.0.0-py3-none-any.whl ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/

    cd ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/
    svn commit -m "pytoolkit update" --username khan --password '1111' --non-interactive

    # cd -
    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish update install script"
}

function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start build whl module"
    #toolkit whl 업데이트
    update_toolkit_whl_module

    #TODO: toolkit 테스트

    WRITE_LOG $FUNCNAME $LINENO "finish build whl module"
}