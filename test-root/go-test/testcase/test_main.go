package main

// package test_module/BaseTest

import (
	// "fmt"
	// "os"

	"fmt"
	"log"
	"testcase/test_module"

	LOG "testcase/local_lib/liblogger"
)

//선언+ 초기화를 한번에 수행하고, 타입을 명시한다.
//전역에서 정상동작 되어야 한다.
var slTestModules = []TestModule {
	//이 문법은 구조체 이다.
	{
		Use:  false, 
		Desc: "기본 테스트",
		//Run:  func() { (&test_module.JsonExample{}).Test() },
		T: &test_module.BaseExample{},
	},

	{
		Use:  false, 
		Desc: "json 테스트",
		T: &test_module.JsonExample{},
	},

	{
		Use:  true, 
		Desc: "dialog 테스트",
		T: &test_module.DialogExample{},
	},
}


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
