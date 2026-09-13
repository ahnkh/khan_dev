package main

import (
	"fmt"
	"os"
	"os/exec"
)

// aivaix 설치 dialog를 실행하고, 바로 install까지 한번에 수행한다. 메모리로 결과 데이터 전달구조
func install() {

	//./venv/pin/python aivax_toolkit.py --debug --method manage_wins_modules --ext_module manage_aivax_install --cmd_category aivax_install --command aivax_install_dialog_menu detail_cmd aivax_install_menu

	cmd := exec.Command(
		"./venv/bin/python",
		"aivax_toolkit.py",
		"--debug",
		// "--printlog",
		"--method", "manage_wins_modules",
		"--ext_module", "manage_aivax_install",
		"--cmd_category", "aivax_install",
		"--command", "aivax_install_dialog_menu",
		"--detail_cmd", "aivax_install_menu",
	)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "install failed: %v\n", err)
		os.Exit(1)
	}
}

//삭제전 install
func preInstall() {

	cmd := exec.Command(
		"tar",
		"xzf",
		"./aivax-patch/toolkit.tar.gz",
		"--strip-components=1",
		"-C",
		".",
	)

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "toolkit extraction failed: %v\n", err)
		os.Exit(1)
	}
}

// 삭제후 처리
func cleanInstall() {

	targets := []string{
		".pyinstall",
		"aivax_toolkit.py",
		"lib_include.py",
		"mainapp",
		"web_app_modules",
		"local_resource",
		"venv",
		"__pycache__",
		".vscode",
	}

	for _, target := range targets {

		if err := os.RemoveAll(target); err != nil {
			fmt.Fprintf(os.Stderr, "failed to remove %s: %v\n", target, err)
			os.Exit(1)
		}
	}
}

func main() {

	if len(os.Args) < 2 {
		fmt.Println("Usage: installer install")
		os.Exit(1)
	}

	// switch os.Args[1] {
	// case "install":
	// 	install()

	// default:
	// 	fmt.Printf("Unknown command: %s\n", os.Args[1])
	// 	os.Exit(1)
	// }

	// 입력된 인자를 순서대로 처리
	for _, arg := range os.Args[1:] {

		switch arg {

		case "pre":
			preInstall()

		case "install":
			install()

		case "clean":
			cleanInstall()

		default:
			fmt.Printf("Unknown command: %s\n", arg)
			os.Exit(1)
		}
	}

	
}