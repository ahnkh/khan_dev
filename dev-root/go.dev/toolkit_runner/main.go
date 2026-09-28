package main

import (
	"fmt"
	"os"
	"os/exec"
)

/**
* toolkit 실행 용도의 별도 binary
* 아주 단순한 프로그램을 제공한다.
* 파라미터는 2개로 제안
 */

// 미리 선언된 구조체, 파라미터에 의해서 선택된 기본 kshell config를 가진다.

//외부 프로세스 실행
func runInitCommand(){


	cmd := exec.Command(
		"/home1/aivax/aivax-venv/bin/python",
		"aivax_toolkit.py",

		"--method", "manage_wins_modules",
		"--ext_module", "manage_aivax_install",
		"--cmd_category", "aivax_install",
		"--command", "aivax_install_dialog_menu",
		"--detail_cmd", "aivax_install_menu",
	)

	cmd.Dir = "/home1/aivax/toolkit"

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "install failed: %v\n", err)
		os.Exit(1)
	}
}


func main() {

	if len(os.Args) < 2 {
		// fmt.Println("Usage: toolkit install")
		os.Exit(1)
	}

	// 입력된 인자를 순서대로 처리
	for _, arg := range os.Args[1:] {

		switch arg {

		case "init":
			runInitCommand()

		default:
			fmt.Printf("Unknown command: %s\n", arg)
			os.Exit(1)
		}
	}

}