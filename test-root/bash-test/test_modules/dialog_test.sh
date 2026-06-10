
g_path=$( cd "$(dirname "$0")" ; pwd )


function test_dialog()
{
    
    WRITE_LOG $FUNCNAME $LINENO "test dialog"

    # 메뉴 테스트
    # dialog [옵션] [박스종류] [텍스트] [높이] [너비]

    # test_menu_dialog
    # test_menu_dialog2

     test_dialog_menu_loop

    # 기본 dialog 테스트
    test_dialog_inputbox
    # test_yesno_dialog

    #색상 테스트
    # test_dialog_color

    # 다중 입력 폼
     test_dialog_form

    # 텍스트 박스, 도움말 출력 용도
     test_dialog_textbox

    # 프로그레스바
    # test_dialog_gauge

    # file, directory 선택
    # test_dialog_file_select

}

function test_dialog_inputbox()
{

    # 단일라인
    # DIALOGRC=test_resource/.dialog.rc dialog --stdout --inputbox "이름 입력" 15 50

    # 다중 라인
    DIALOGRC=test_resource/.dialog.rc dialog --stdout \
        --backtitle "SNIPER AIVAX V1.0.0.0" \
        --title "Please Check Final Config" \
        --tab-correct \
        --editbox ~/.bash_profile 15 50

}

# yes/no dialog
function test_yesno_dialog()
{
    # 기본 dialog 테스트
    DIALOGRC=test_resource/.dialog.rc dialog --clear --yesno "삭제하시겠습니까?" 20 40
}

# 메뉴
function test_menu_dialog()
{
    DIALOGRC=./test_resource/.dialog.rc dialog --stdout --no-cancel \
        --menu "Select AIVAX Install Menu" \
        15 50 5 \
        1 "Factory Install" \
        2 "Patch Install" \
        3 "Serial License" \
        "-" ────────────── \
        4 "Uninstall" \
        5 "Initialize Data" \
        "-" ────────────── \
        6 "Version" \
        7 "Exit"
        
        # "" -------------- \
        # "-" ──────────────────────── \

    # # 다음의 무시코드가 필요하다.
    # case "$choice" in
    #     "-")
    #         ;;
    #     1)
    #         echo "factory"
    #         ;;
    # esac

    # echo "$choice" 
}

# 메뉴, AI 추천, 테스트 2
# function test_menu_dialog2()
# {
#     choice=$(dialog --stdout \
#         --menu "\
# Install Menu
# --------------------------------
# Installation
# --------------------------------" \
#         18 60 10 \
#         1 "Factory Install" \
#         2 "Patch Install" \
#         2 "Patch Install" \
#         3 "Uninstall" \
#         4 "Initialize Data" \
#         5 "Version" \
#         6 "Exit"
#     )

#     echo "$choice"

# }

# 메뉴, 입력창 loop
function test_dialog_menu_loop()
{
    while true
    do
        # choice=$(DIALOGRC=./test_resource/.dialog.rc dialog --stdout --no-cancel --no-ok --cursor-off-label --no-buttons \
        choice=$(DIALOGRC=./test_resource/.dialog.rc dialog --stdout --shadow \
        --ok-label "SELECT" \
        --cancel-label "EXIT" \
        --backtitle "SNIPER AIVAX V1.0.0.0" \
        --title "AIVAX INSTALLER" \
        --menu "Select Install Menu" \
        16 40 10 \
        1 "Factory Install" \
        2 "Patch Install" \
        3 "Serial License" \
        "-" ────────────── \
        4 "Uninstall" \
        5 "Initialize Data" \
        6 "Version"
        )

        rc=$?

        # ESC 포함 모든 비정상 종료 무시
        [ $rc -ne 0 ] && continue

        break
    done
}

# 색상 확인 => 크게 의미는 없어 보인다. (에러 로그 정도?)
function test_dialog_color()
{

    # \Z0	기본
    # \Z1	빨강
    # \Z2	초록
    # \Z3	노랑
    # \Z4	파랑
    # \Z5	마젠타
    # \Z6	시안
    # \Z7	흰색

    DIALOGRC=test_resource/.dialog.rc dialog --colors --msgbox "\Z1빨간색 \Zn기본색 \Z7흰색" 10 40
}

# 다중 입력 form, 입력 Text
function test_dialog_form()
{
    DIALOGRC=test_resource/.dialog.rc dialog --stdout \
    --form "사용자 정보" \
    15 60 5 \
    "Serial Number:"     1 1 "" 1 15 30 0 \
    "License:"   2 1 "" 2 15 30 0 
}

# 진행바 => 구문 이해 필요
function test_dialog_gauge()
{
    (
        for i in {1..100}
        do
            echo $i
            sleep 0.05
        done
    ) | DIALOGRC=test_resource/.dialog.rc dialog --gauge "설치중..." 10 60 0
}



# textbox
function test_dialog_textbox()
{
    # dialog [옵션] [박스종류] [텍스트] [높이] [너비]    
    DIALOGRC=test_resource/.dialog.rc dialog --textbox ~/.bash_profile 35 70
}

# file, directory 선택 (사양, 좀더 확인 ㅣ필요)
function test_dialog_file_select()
{
    # file 선택
    # dialog --stdout --fselect /etc/ 20 70

    # directory 선택
    dialog --stdout --dselect /home/ 20 70
}
