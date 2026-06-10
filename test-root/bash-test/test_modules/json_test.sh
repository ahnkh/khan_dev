
g_path=$( cd "$(dirname "$0")" ; pwd )

function test_json()
{
    WRITE_LOG $FUNCNAME $LINENO "test json"

    test_jq
}


#json를 통한 json 문자열 테스트
function test_jq()
{
    # NAME="aivax"
    # PORT=8080

    # json=$(jq -n \
    #     --arg name "$NAME" \
    #     --argjson port "$PORT" \
    #     '{name:$name, port:$port}')


    method='["manage_wins_modules"]'
    ext_module="manage_aivax_install"
    cmd_category="aivax_install"
    command="aivax_install_util_module"
    detail_cmd="generate_version"

    serial_key=""
    license_key=""
    serial_file=""
    version_default_file=""

    json=$(jq -n \
        --argjson method "$method" \
        --arg ext_module "$ext_module" \
        --arg cmd_category "$cmd_category" \
        --arg command "$command" \
        --arg detail_cmd "$detail_cmd" \
        --arg serial_key "$serial_key" \
        --arg license_key "$license_key" \
        --arg serial_file "$serial_file" \
        --arg version_default_file "$version_default_file" \
        '{
            method:$method, 
            ext_module:$ext_module,
            cmd_category: $cmd_category,
            command: $command,
            detail_cmd: $detail_cmd,
            serial_key: $serial_key,
            license_key: $license_key,
            serial_file: $serial_file,
            version_default_file: $version_default_file
        }')



    # --argjson  method "[\"manage_wins_modules\"]" \
    # --arg ext_module "manage_aivax_install" \
    # --arg cmd_category "aivax_install" \
    # --arg command "aivax_install_util_module" \
    # --arg detail_cmd "generate_version" \

    # --arg detail_cmd "generate_version" \
    # --arg detail_cmd "generate_version" \
    # --arg detail_cmd "generate_version" \
    # --arg detail_cmd "generate_version" \

    echo "$json"
}
