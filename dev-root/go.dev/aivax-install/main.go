package aivaxinstall

import (
	"encoding/json"
	"fmt"
	"os"
)

// 상수, 우선 하나의 파일로 정의
const (
	
	BOLD string = "\x1b[1m"

	RED string = "\x1b[31m"
	GREEN string = "\x1b[32m"
	BLUE string = "\x1b[34m"
	YELLOW string = "\x1b[33m"
	MAGENTA string = "\x1b[36m"
	GRAY string = "\x1b[90m"
	PURPLE string = "\x1b[35m"
	WHITE string = "\x1b[37m"

	NC string = "\x1b[0m"

	LOCAL_JSON_PATH string = "/config.json"
)

/**
* AIVAX 패키지 installer
 */

//기본 설정 초기화 로직 추가
func init_default_setup(){

	/**
	* 디렉토리 생성, 과거 디렉토리가 존재하면, old 생성후, aivax 파일 이동
	*/

}

// 최초, local config 추가
func load_local_config(){

	/**
	* config 경로는 우선 고정, 로컬 상수로
	*/

	data, err := os.ReadFile(LOCAL_JSON_PATH)
	if nil != err {
		panic(err)
	}

	var config map[string]interface{}

	if err := json.Unmarshal(data, &config); err != nil {
		panic(err)
	}

}

//로깅 추가


//모듈별 설치, 메인
func install_module(){
	/**
	*
	*/
}


//메인 함수
func main() {

	//임시, print 구문 추가
	fmt.Println("start install aivax")

	load_local_config()

	//패치전 서비스 종료 - 우선 개발, 이후 각 기능, 개별 서비스 종료 기능 
	//서비스 종료는 별도의 명령으로 다시 제공

	init_default_setup()

	//모듈별 설치
	install_module()

	//aivax 소스 패치

	//프로세스, 재기동

	//임시, 설치 종료 print 구문 추가
	fmt.Println("finish install aivax")
	
}