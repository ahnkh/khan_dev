
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

# toolkit config 업데이트
function update_toolkit_config()
{
    # git_root=/home1/git-root

    WRITE_LOG $FUNCNAME $LINENO "start update toolkit config"

    cd ${git_root}/aivax_toolkit

    git pull

    # resource, 하나씩 추가
    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/config/subconfig/ext_config_util.json ${git_root}/aivax_toolkit/local_resource/config/subconfig
    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/config/subconfig/ext_config_wins.json ${git_root}/aivax_toolkit/local_resource/config/subconfig

    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/config/wins-config.json ${git_root}/aivax_toolkit/local_resource/config/
    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/config/wins_resource.json ${git_root}/aivax_toolkit/local_resource/config/

    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/db_resource/sql_query_map/rdb_query/json/* ${git_root}/aivax_toolkit/local_resource/config/db_resource/sql_query_map/rdb_query/json/

    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/http_query_map/wins_query/* ${git_root}/aivax_toolkit/local_resource/http_query_map/wins_query/

    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/local_resource/script_config/aivax/* ${git_root}/aivax_toolkit/local_resource/script_config/aivax/


    cd $g_path


    WRITE_LOG $FUNCNAME $LINENO "finish update toolkit config"
}

# toolkit source 업데이트
function update_toolkit_source()
{
    # git_root=/home1/git-root

    WRITE_LOG $FUNCNAME $LINENO "start update toolkit source"

    cd ${git_root}/aivax_toolkit

    git pull

    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/aivax_toolkit.py ${git_root}/aivax_toolkit/
    \cp -rfv ${git_root}/khan.pythonscript/khan-shell-interface/lib_include_wins.py ${git_root}/aivax_toolkit/lib_include.py

    #TODO: 나머지 소스는 실제 수정이 필요하면 직접 commit

    cd $g_path

    WRITE_LOG $FUNCNAME $LINENO "start update toolkit source"
}

# pytoolkit whl 빌드
function build_toolkit_whl_module()
{
    # git_root=/home1/git-root

    WRITE_LOG $FUNCNAME $LINENO "start update toolkit whl module"

    # ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/

    # svn 업데이트, svn commit 보다는 신규 생성쪽으로
    mkdir -p ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build

    cd ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/
    svn update --username khan --password '1111' --non-interactive

    # python temp dir 경로의 whl 정리
    rm -rf ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/operation_util_manage_modules
    rm -rf ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/wins_manage_modules

    rm -rfv ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/dist/*

    # toolkit 소스 업데이트, 복사
    cp -rf ${git_root}/khan.pythonscript/khan-shell-interface/util_modules/operation_util_manage_modules ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/
    cp -rf ${git_root}/khan.pythonscript/khan-shell-interface/util_modules/wins_manage_modules ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/util_modules/

    # python build
    # cd ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/

    #ubuntu는 python3
    python -m build > /dev/null #TODO: 오류, 로그는 향후 정리

    unzip -l dist/pytoolkit-1.0.0-py3-none-any.whl | head -100

    #uv 테스트
    uv pip install --force-reinstall dist/pytoolkit-1.0.0-py3-none-any.whl

    # build 결과물 업데이트 및 소스 commit
    # TODO: 오타가 있다. build_ouput -> build_output 점진적으로 고치자.
    cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/toolkit_build/dist/pytoolkit-1.0.0-py3-none-any.whl ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/

    cd ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/
    svn update --username khan --password '1111' --non-interactive
    svn commit -m "pytoolkit update" --username khan --password '1111' --non-interactive

    # commit후, 설치된 모듈을 지운다.
    uv pip uninstall pytoolkit

    # cd -
    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish update install script"
}

# service 빌드
function build_service_whl_module()
{
    # git_root=/home1/git-root

    WRITE_LOG $FUNCNAME $LINENO "start build service whl module"

    # ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/
    
    mkdir -p ${git_root}/khan.pythonscript/python-build-tempdir/service_module_build

    cd ${git_root}/khan.pythonscript/python-build-tempdir/service_module_build/
    svn update --username khan --password '1111' --non-interactive

    # python temp dir 경로의 whl 정리
    rm -rf ${git_root}/khan.pythonscript/python-build-tempdir/service_module_build/service_modules

    rm -rf ${git_root}/khan.pythonscript/python-build-tempdir/service_module_build/dist/*

    \cp -rf ${git_root}/khan.pythonscript/khan-shell-interface/service_modules ${git_root}/khan.pythonscript/python-build-tempdir/service_module_build/

    #ubuntu는 python3
    python -m build > /dev/null

    unzip -l dist/pyservice-1.0.3-py3-none-any.whl | head -100

    #uv 테스트
    uv pip install --force-reinstall dist/pyservice-1.0.3-py3-none-any.whl

    # build 결과물 업데이트 및 소스 commit
    # TODO: 오타가 있다. build_ouput -> build_output 점진적으로 고치자.
    \cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/service_module_build/dist/pyservice-1.0.3-py3-none-any.whl ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/

    cd ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/
    svn update --username khan --password '1111' --non-interactive

    svn status
    svn commit -m "pyservice update" --username khan --password '1111' --non-interactive
    svn status

    # commit후, 설치된 모듈을 지운다.
    uv pip uninstall pyservice

    # cd -
    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish build service whl module"
}

# pycomlibex 빌드
function build_pycomlibex_whl_module()
{
    # git_root=/home1/git-root
    WRITE_LOG $FUNCNAME $LINENO "start build pycomlibex whl module"

    mkdir -p ${git_root}/khan.pythonscript/python-build-tempdir/common_module_build

    cd ${git_root}/khan.pythonscript/python-build-tempdir/common_module_build/
    svn update --username khan --password '1111' --non-interactive

    # python temp dir 경로의 whl 정리
    rm -rf ${git_root}/khan.pythonscript/python-build-tempdir/common_module_build/common_modules

    rm -rf ${git_root}/khan.pythonscript/python-build-tempdir/common_module_build/dist/*

    \cp -rf ${git_root}/khan.pythonscript/khan-shell-interface/common_modules ${git_root}/khan.pythonscript/python-build-tempdir/common_module_build/

    #ubuntu는 python3
    python -m build > /dev/null

    unzip -l dist/pycomlibex-1.1.2-py3-none-any.whl | head -100

    #uv 테스트
    uv pip install --force-reinstall dist/pycomlibex-1.1.2-py3-none-any.whl

    # build 결과물 업데이트 및 소스 commit
    # TODO: 오타가 있다. build_ouput -> build_output 점진적으로 고치자.
    \cp -rfv ${git_root}/khan.pythonscript/python-build-tempdir/common_module_build/dist/pycomlibex-1.1.2-py3-none-any.whl ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/

    cd ${git_root}/khan.pythonscript/python-build-tempdir/build_ouput/
    svn update --username khan --password '1111' --non-interactive

    svn status
    svn commit -m "pycomlibex update" --username khan --password '1111' --non-interactive
    svn status

    uv pip uninstall pycomlibex

    # cd -
    cd ${g_path}

    WRITE_LOG $FUNCNAME $LINENO "finish build pycomlibex whl module"
}

function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start build whl module"

    #toolkit config 업데이트
    update_toolkit_config

    #toolkit 소스 업데이트
    update_toolkit_source

    #toolkit whl 업데이트
    build_toolkit_whl_module

    #pyservice 업데이트
    build_service_whl_module

    #pycommlibex 업데이트
    build_pycomlibex_whl_module

    #TODO: toolkit 테스트

    WRITE_LOG $FUNCNAME $LINENO "finish build whl module"
}

main $@