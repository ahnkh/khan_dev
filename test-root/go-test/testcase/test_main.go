package main

// package test_module/BaseTest

import (
	// "fmt"
	// "os"

	"fmt"
	"log"

	LOG "testcase/local_lib/liblogger"
)

//최초 시작, TODO: init 함수는 여러개를 만들수 있다. 하지만 모호하므로 1개만 사용하자.
//go언어는 클래스, static 생성자가 없기네, 싱글턴 패턴 최소화, 명시적 초기화를 선호하여 생성된 개념이다.
func init() {
    // fmt.Println("init 실행")

	var strLogFile string = "trace-log/testcase.log"

	// LOG.InitializeLogger(strLogFile, zapcore.DebugLevel)
	LOG.InitializeLogger(strLogFile, -1)
}

func main() {
	log.Println("start go testcase")

	//logger 테스트
	// LOG.Debug(BH("start process"))
	LOG.Info(BH("start process"))

	for _, tm := range slTestModules {
		if true == tm.Use {
			var strMessage string

			strMessage = fmt.Sprintf("run test %s\n", tm.Desc)

			// log.Print(BH(strMessage))
			log.Print(strMessage)
			tm.T.Test()
		}
	}
}
