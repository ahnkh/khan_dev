package main

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
)
const (
    python_venv string = "/home1/aivax/aivax-venv/bin/python"
    toolkit_path    string = "/home1/aivax/toolkit"

)

type Config struct {
    PythonPath string
    WorkDir    string
	AivaxToolkit string
}

var config = Config{
    PythonPath: "/home1/aivax/aivax-venv/bin/python",
    WorkDir:    "/home1/aivax/toolkit",
	AivaxToolkit: "aivax_toolkit.py",
}

func main() {

	// 1. 외부에서 JSON 문자열 입력받기
	// input, err := io.ReadAll(os.Stdin)
	input := []byte(os.Args[1])
	// if err != nil {
	// 	fmt.Fprintln(os.Stderr, "입력 실패:", err)
	// 	panic(err)
	// 	// os.Exit(1)
	// }

	// 2. JSON 문자열을 map으로 변환
	var data map[string]any

	if err := json.Unmarshal([]byte(input), &data); err != nil {
		fmt.Println("JSON 파싱 실패:", err)
		panic(err)
		// return
	}

	// 3. 기존 JSON에 항목 추가

	data["keywords"] = []string{
		"manage_wins_module",
	}

	data["ext_module"] = "manage_etc_util_module"
	data["cmd_category"] = "etc_util_module"
	data["command"] = "mail_client"

	data["api_print_console"] = 1

	// 4. map을 JSON 문자열로 변환
	jsonData, err := json.Marshal(data)
	if err != nil {
		fmt.Println("JSON 변환 실패:", err)
		panic(err)
		// return
	}

	// 확인용 출력
	fmt.Println("최종 JSON:", string(jsonData))

	// 5. Python 프로세스 실행
	// cmd := exec.Command(
	// 	"/usr/local/bin/python3",
	// 	"/home1/aivax/process.py",
	// )

	err = os.Chdir(config.WorkDir)
	if err != nil {
		fmt.Printf("chdir failed: %v\n", err)
		panic(err)
	}

	// 6. JSON 문자열을 명령행 인자로 Python에 전달
	cmd := exec.Command(
		config.PythonPath,
		config.AivaxToolkit,
		"--script_config",
		string(jsonData),
	)

	// JSON 문자열을 Python의 stdin으로 전달
	// cmd.Stdin = bytes.NewReader(jsonData)

	// 6. Python 실행 및 결과 수신
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Python 실행 실패:", err)
		fmt.Println(string(output))
		panic(err)
		// return
	}

	// fmt.Println("Python 결과:", string(output))
}


/** 실행

JSON_DATA=$(jq -n \
'{
    mail_url: "175.113.82.233",
    mail_port: "25",    
    from_mail: "ghahn@wins21.co.kr",
    recv_mail_list: ["ghahn@wins21.co.kr"],
	subject: "[AIVAX] winstest 게정 로그인 인증 실패 횟수 초과",
	contents : "winstest 계정의 로그인 인증 실패 횟수를 초과하였습니다. <br/> 알람 요약 : winstest 인증 횟수 초과 : 5회 <br/> 발생시간 : 2026-10-13 12:00:00",
	mail_loginid : "",
	mail_loginpw : "",
	"use_tls" : false,
	timeout : 10    
}') || exit 1

./mail_client $JSON_DATA


**/


// func main() {

// 	jsonData, err := io.ReadAll(os.Stdin)
// 	if err != nil {
// 		fmt.Fprintln(os.Stderr, err)
// 		os.Exit(1)
// 	}

// 	// JSON 유효성 검사
// 	if !json.Valid(jsonData) {
// 		fmt.Fprintln(os.Stderr, "잘못된 JSON")
// 		os.Exit(1)
// 	}

// 	// 외부 프로세스 실행
// 	cmd := exec.Command(
// 		config.PythonPath,
// 		config.AivaxToolkit,
// 	)
// 	cmd.Stdin = bytes.NewReader(jsonData)

// 	output, err := cmd.CombinedOutput()
// 	if err != nil {
// 		fmt.Fprintln(os.Stderr, err)
// 		os.Exit(1)
// 	}

// 	fmt.Println(string(output))
// }