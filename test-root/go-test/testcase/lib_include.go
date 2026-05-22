/**
* 전역 데이터 관리, lib_include로 kshell과 통일
* 최초 시작시 vscode의 go 플러그인이 개행을 제거하는 문제, 소스코드의 시작은 주석으로 시작하자.
 */
package main

// import (
// 	// "fmt"
// 	// "os"

// )

//패키지 시작시 자동으로 호출된다.
//순서 init 실행, 이후 main 실행.
func init() {
    // fmt.Println("init 실행")
}

// 인터페이스 방식도 있다. 함수가 Test라는 가정하에 사용 일단 사용하고, 향후에 배워보자.
//"Test() 메서드를 가진 타입은 모두 Tester다" 아직은 잘 모르겠다. 일단 써보자.
type Tester interface {
	Test()
}

// TODO: struct, 일단 써보자.
type TestModule struct {
	Use  bool
	Desc string
	//Run  func()
	T    Tester
}

//전역 변수에 대한 관리
// 이 문법은 slice 이다.
//TODO: 전역변수 접근시 이름 규칙이 존재한다. 
// 대문자로 시작 : 다른 패키지에서 접근 가능 
//소문자로 시작 : 같은 패키지에서만 사용 가능



///////////////////////////////////////////////////////////////////// main 패키지에서만 사용하는 변수

//TODO: 전역 영역에서는 재할당이 불가능하다. 
//반드시 선언과 동시에 초기화 해야 한다.
//nil로 선언하고 초기화를 하고 싶다면, init() 함수를 사용한다. (나중에 다시 확인)
//init 함수는 패키지에서 한번만 호출되는 함수로, go만의 문법이 따로 있다.
/*
var slTestModules []TestModule

func init() {
    slTestModules = []TestModule{
        {
            Use:  true,
            Desc: "기본 테스트",
            T:    &test_module.BaseExample{},
        },
        {
            Use:  false,
            Desc: "json 테스트",
            T:    &test_module.JsonExample{},
        },
    }
}
*/

//잘못된 문법, 처음 배우는 단계이니 이력 추가.
// var slTestModules []TestModule = nil

// []slTestModules = {
// 	//이 문법은 구조체 이다.
// 	{
// 		Use:  true, 
// 		Desc: "기본 테스트",
// 		//Run:  func() { (&test_module.JsonExample{}).Test() },
// 		T: &test_module.BaseExample{},
// 	},

// 	{
// 		Use:  false, 
// 		Desc: "json 테스트",
// 		T: &test_module.JsonExample{},
// 	},
// }



//색상 정의 - 향후 전역 define으로 이동
//TODO: 아직 GO가 익숙하지 않아서, 이렇게 처리
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

//BOLD 처리, zapcore에서 지원되지 않아서 별도로 호출 필요
//TODO: GO언어가 익숙해지면, 좀더 유연하게 처리.
func BH(msg string) string {
    // const WHITE = "\x1b[37m"
    // const BOLD  = "\x1b[1m"
    // const NC    = "\x1b[0m"

    return BOLD + WHITE + msg + NC
}