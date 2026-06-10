
g_path=$( cd "$(dirname "$0")" ; pwd )

source global.sh


# test main
function main()
{
    WRITE_LOG $FUNCNAME $LINENO "start bash test case"

    # dialog test
    # source test_modules/dialog_test.sh
    # test_dialog

    # json test
    source test_modules/json_test.sh
    test_json

    WRITE_LOG $FUNCNAME $LINENO "finish bash test case"
}

main $@