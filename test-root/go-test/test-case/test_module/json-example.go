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

//json 파일 로딩 기능 테스트
func (t *JsonExample) testLoadJsonFile() {

	//기본 로그 출력, 아직 정착되지 않았다.
	fmt.Println("test load json file")

	data, err := os.ReadFile("test-resource/config.json")
	if err != nil {
		panic(err)
	}

	var config map[string]interface{}
	
	if err := json.Unmarshal(data, &config); err != nil {
		panic(err)
	}

	fmt.Println(config)
	fmt.Println(config["host"])

}
