package test_module

import (
	"fmt"
	"os/exec"
	"strings"
	// LOG "testcase/local_lib/liblogger"
)

type DialogExample struct{}


func (t *DialogExample) Test() {

	//dialog 에제 테스트
	t.testBaseDialog()
}

func (t *DialogExample) testBaseDialog(){
	

	fmt.Println("test base dialog")

	cmd := exec.Command(
		"dialog",
		"--stdout",
		"--title", "OpenSearch Installer",
		"--form", "Installation Config",
		"15", "60", "3",

		"HTTP Port:", "1", "1", "9200",
		"1", "20", "20", "0",

		"Install Path:", "2", "1",
		"/opt/opensearch",
		"2", "20", "30", "0",
	)

	output, err := cmd.Output()

	//error는 %v를 사용한다. 문자열은 %s
	//Println 과 Printf는 다르다.
	fmt.Printf("dialog input text = %s, error = %v\n", output, err)

	if err != nil {
		fmt.Println("cancel or error:", err)
		return
	}

	//form 의 경우 \n로 분리되어서 순차적으로 들어온다.
	values := strings.Split(strings.TrimSpace(string(output)), "\n",)

	// 사용시 이렇게 쓰면 된다.
	fmt.Println("PORT :", values[0])
	fmt.Println("PATH :", values[1])

}