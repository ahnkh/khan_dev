package main

import (
	"fmt"
	"io"
	"os"
	"os/exec"
)

//TODO: 대문자로 시작하면, 외부에서 접근할수 있게 된다. 소문자로 관리
const (
    python_venv string = "/home1/aivax/aivax-venv/bin/python"
    toolkit_path    string = "/home1/aivax/toolkit"

    // Port       int    = 9099
    // Debug      bool   = true
)

//TODO: struct쪽이 더 가독성이 있어 보인다.
type Config struct {
    PythonPath string
    WorkDir    string
	AivaxToolkit string
    // Port       int
    // Debug      bool
}

var config = Config{
    PythonPath: "/home1/aivax/aivax-venv/bin/python",
    WorkDir:    "/home1/aivax/toolkit",
	AivaxToolkit: "aivax_toolkit.py",
    // Port:       9099,
    // Debug:      true,
}

////////////////////////////////////// command

// aivaix 설치 dialog를 실행하고, 바로 install까지 한번에 수행한다. 메모리로 결과 데이터 전달구조
func install() {

	//./venv/pin/python aivax_toolkit.py --debug --method manage_wins_modules --ext_module manage_aivax_install --cmd_category aivax_install --command aivax_install_dialog_menu detail_cmd aivax_install_menu

	cmd := exec.Command(
		"./venv/bin/python",
		config.AivaxToolkit,
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

	var cmd *exec.Cmd

	cmd = exec.Command(
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

	// 에러 변수
	var errCopyHwMetric error
	var errCopyProcMon error

	//h_sensor 복사
	// errCopyHwMetric := copyFile("./extension/python-install/hw_metric", "/usr/bin/hwmon")
	errCopyHwMetric = copyFile("./extension/python-install/hw_metric", "/usr/local/bin/hwprobe")
	if errCopyHwMetric != nil {
		fmt.Fprintf(os.Stderr, "hw_metric copy failed: %v\n", errCopyHwMetric)
		panic(errCopyHwMetric)
	}

	//toolkit 복사 procmon
	errCopyProcMon = copyFile("./.installer", "/usr/local/bin/procmon")
	if errCopyProcMon != nil {
		fmt.Fprintf(os.Stderr, "procmon copy failed: %v\n", errCopyProcMon)
		panic(errCopyProcMon)
	}

	//gopy 복사
	errCopyProcMon = copyFile("./.installer", "/usr/local/bin/procmon")
	if errCopyProcMon != nil {
		fmt.Fprintf(os.Stderr, "procmon copy failed: %v\n", errCopyProcMon)
		panic(errCopyProcMon)
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

func runInitCommand(_strCommand string) {

	//TODO: 쉘스크립트에 작성후 실행, toolkit을 노출하지 않는다.
	//TOOD: 외부 스크립트 종속성 최소화

	// cmd := exec.Command("./sys_check_d")
	// cmd.Dir = "/home1/aivax/toolkit"

	var errCopyFile error = nil

	//지정된 파일을 복사한다.
	errCopyFile = copyFile(".test.py", ".toolkit.pyc")
	if errCopyFile != nil {
		fmt.Fprintf(os.Stderr, "toolkit copy failed: %v\n", errCopyFile)
		panic(errCopyFile)
	}

	err := os.Chmod(".toolkit.pyc", 0755)
	if err != nil {
		fmt.Printf("mode failed: %v\n", err)
		os.Exit(1)
	}

	var cmd *exec.Cmd = nil

	cmd = exec.Command(
		".toolkit.pyc",
		_strCommand,
	)

	// cmd.Dir = "/home1/aivax/toolkit"
	cmd.Dir = config.WorkDir

	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	if err := cmd.Run(); err != nil {
		fmt.Fprintf(os.Stderr, "init failed: %v\n", err)
		os.Exit(1)
	}
}

//////////////////////////////////////// 내장 명령
func copyFile(src, dst string) error {
    in, err := os.Open(src)
    if err != nil {
        return err
    }
    defer in.Close()

    out, err := os.Create(dst)
    if err != nil {
        return err
    }
    defer out.Close()

    _, err = io.Copy(out, in)
    return err
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

		case "init":
			runInitCommand(arg)

		default:
			fmt.Printf("Unknown command: %s\n", arg)
			os.Exit(1)
		}
	}

	
}