package main

// package test_module/BaseTest

import (
	// "fmt"
	// "os"
	"log"

	"test-case/test_module"
)

// TODO: 일단 써보자.
type TestModule struct {
	Use  bool
	Desc string
	Run  func()
}

func main() {
	log.Println("start go testcase")

	// 이 문법은 slice 이다.
	slTestModules := []TestModule{
		//이 문법은 구조체 이다.
		{
			Use:  false, 
			Desc: "기본 테스트",
			Run: func() {
				t := &test_module.BaseExample{}
				t.Test()
			},
		},

		{
			Use:  true, 
			Desc: "json 테스트",
			Run: func() {
				t := &test_module.JsonExample{}
				t.Test()
			},
		},
	}

	for _, tm := range slTestModules {
		if true == tm.Use {
			log.Printf("run test %s\n", tm.Desc)
			tm.Run()
		}
	}
}
