package test_module

import (
	"encoding/json"
	"fmt"
	"os"
)

type JsonExample struct{}

func (t *JsonExample) Test() {

	//json 파일 로딩 기능 테스트
	t.testLoadJsonFile()
}

// json 파일 로딩 기능 테스트
//j는 receiver로 this, self 느낌이다. 
//이러면 클래스 개념도 적용 가능할듯?
func (t *JsonExample) testLoadJsonFile() {

	// const (
	// 	DebugLevel Level = -1
	// 	InfoLevel  Level = 0
	// 	WarnLevel  Level = 1
	// 	ErrorLevel Level = 2
	// )

	// func LevelFromString(s string) zapcore.Level {
	// 	switch s {
	// 	case "debug":
	// 		return zapcore.DebugLevel
	// 	case "info":
	// 		return zapcore.InfoLevel
	// 	case "warn":
	// 		return zapcore.WarnLevel
	// 	case "error":
	// 		return zapcore.ErrorLevel
	// 	default:
	// 		return zapcore.InfoLevel
	// 	}
	// }

	// config라면 이렇게 처리
	// {
	// 	"logFile": "daemon.log",
	// 	"logLevel": "debug",
	// 	"stdout": true
	//   }

	//관련 구조체
	// type LogConfig struct {
	// 	LogFile string `json:"logFile"`
	// 	LogLevel string `json:"logLevel"`
	// 	Stdout bool `json:"stdout"`
	// }

	//기본 로그 출력, 아직 정착되지 않았다.
	fmt.Println("test load json file")

	data, err := os.ReadFile("test-resource/config.json")
	if nil != err {
		panic(err)
	}

	var config map[string]interface{}

	if err := json.Unmarshal(data, &config); err != nil {
		panic(err)
	}

	fmt.Println(config)
	fmt.Println(config["host"])

}
