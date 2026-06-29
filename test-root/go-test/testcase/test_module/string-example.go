package test_module

import (
	"fmt"
	/*"os/exec"
	"strings"*/// LOG "testcase/local_lib/liblogger"
)

/**
* string 관련 테스트
 */

type StringExample struct {}


func (t *StringExample) Test() {

	//fmt 의 print에 대한 테스트
	t.testFmtPrint()
	
}

//fmt의 print 계열 함수를 테스트 한다.
func (t *StringExample) testFmtPrint() {

	fmt.Println("test fmt print")
}

