
g_path=$( cd "$(dirname "$0")" ; pwd )

source global.sh
source test_modules/dialog_test.sh


# test main
function main()
{
    # dialog test
    test_dialog
}

main $@