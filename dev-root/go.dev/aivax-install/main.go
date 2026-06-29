package main

import (
	im "aivax-install/install_modules"
	"encoding/json"

	// "fmt"
	"log"
	"os"
)

//우선 하나로 작성후 모듈 분리

/***
* //최초 시작, 가장 기본적인 core 모듈의 설치
* rpm, python이 가장 시작이다.
 */
func install_base_module(){

	

}


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

	//내부 config 경로
	var strInstallConfig string = globalValue.strInstallConfig

	data, err := os.ReadFile(strInstallConfig)
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

	//os_env_install
	// osEnvInstall := &im.OsEnvInstall{}
	var osEnvInstall im.OsEnvInstall

	osEnvInstall.InstallOsEnv()
}

//최초 시작시 수행
func init() {

}


//메인 함수
func main() {

	//임시, print 구문 추가
	// fmt.Println("start install aivax")
	log.Println("start install aivax")

	//최초 config, 기본 실행, config/install.json으로 지정
	load_local_config()

	//패치전 서비스 종료 - 우선 개발, 이후 각 기능, 개별 서비스 종료 기능 
	//서비스 종료는 별도의 명령으로 다시 제공

	install_base_module()

	init_default_setup()

	//모듈별 설치
	install_module()

	//aivax 소스 패치

	//프로세스, 재기동

	//임시, 설치 종료 print 구문 추가
	log.Println("finish install aivax")
	
}