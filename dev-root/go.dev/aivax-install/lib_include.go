package main

// 상수, 이름 지정
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

)

// 상수 설정, next
// const (
// 	LOCAL_JSON_PATH string = "/config.json"
// )

// 전역 변수 관리
type GlobalStateStruct struct {

	// 설치 config
	strInstallConfig string

}

// 이렇게 선언하는 방법도 있다?
var globalValue = GlobalStateStruct {
	strInstallConfig : "./data-setup/install-setup/config.json",

}

//TODO: 기본 config에서 외부 설정 경로가 존재한다.
//log - 설정 기능 부터

//dummy 변수 추가, 변수 선언이 항상 헷갈린다.
var intValue int = 0
var strValue string = ""

//여러변수, 참고용
// var (
// 	intValue int = 0
// 	strValue string = ""
// )