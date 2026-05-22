// package tviewui

// // main은 반드시 main으로 시작해야 한다.
// // package main

// import (
// 	"fmt"
// 	"os/exec"
// 	"strings"

// 	"github.com/rivo/tview"
// )

// func main() {
// 	app := tview.NewApplication()

// 	// 로그 출력 창
// 	// logView := tview.NewTextView().
// 	// 	SetDynamicColors(true).
// 	// 	SetScrollable(true).
// 	// 	SetBorder(true).
// 	// 	SetTitle(" Install Log ")

// 	// logView.Write([]byte("[green]OpenSearch Installer 시작...\n"))

// 	logView := tview.NewTextView()
// 	logView.SetDynamicColors(true)
// 	logView.SetScrollable(true)
// 	logView.SetBorder(true)
// 	logView.SetTitle(" Install Log ")

// 	fmt.Fprintln(logView, "[green]OpenSearch Installer 시작...")

// 	// 입력 Form
// 	form := tview.NewForm()

// 	var installType string
// 	installType = "Single"

// 	// form.
// 	// 	AddDropDown(
// 	// 		"Install Type",
// 	// 		[]string{"Single", "Cluster"},
// 	// 		0,
// 	// 		func(option string, index int) {
// 	// 			installType = option
// 	// 		},
// 	// 	).
// 	// 	AddInputField(
// 	// 		"HTTP Port",
// 	// 		"9200",
// 	// 		10,
// 	// 		nil,
// 	// 		nil,
// 	// 	).
// 	// 	AddInputField(
// 	// 		"Install Path",
// 	// 		"/opt/opensearch",
// 	// 		30,
// 	// 		nil,
// 	// 		nil,
// 	// 	).
// 	// 	AddCheckbox(
// 	// 		"Install Dashboard",
// 	// 		true,
// 	// 		nil,
// 	// 	)

// 	form.AddDropDown(
// 		"Install Type",
// 		[]string{"Single", "Cluster"},
// 		0,
// 		func(option string, index int) {
// 			installType = option
// 		},
// 	)

// 	form.AddInputField(
// 		"HTTP Port",
// 		"9200",
// 		10,
// 		nil,
// 		nil,
// 	)

// 	form.AddInputField(
// 		"Install Path",
// 		"/opt/opensearch",
// 		30,
// 		nil,
// 		nil,
// 	)

// 	form.AddCheckbox(
// 		"Install Dashboard",
// 		true,
// 		nil,
// 	)

// 	form.AddButton("Install", func() {

// 		port := form.GetFormItem(1).(*tview.InputField).GetText()
// 		path := form.GetFormItem(2).(*tview.InputField).GetText()

// 		log(logView, "[yellow]설치 시작")
// 		log(logView, fmt.Sprintf("[white]Type: %s", installType))
// 		log(logView, fmt.Sprintf("[white]Port: %s", port))
// 		log(logView, fmt.Sprintf("[white]Path: %s", path))

// 		// 예제 명령 실행
// 		runCommand(logView, "echo Installing OpenSearch...")
// 		runCommand(logView, "sleep 1")
// 		runCommand(logView, "echo Creating Config...")
// 		runCommand(logView, "sleep 1")
// 		runCommand(logView, "echo Starting Service...")
// 		runCommand(logView, "sleep 1")
// 		runCommand(logView, "echo Health Check OK")

// 		log(logView, "[green]설치 완료!")
// 	})

// 	form.AddButton("Quit", func() {
// 		app.Stop()
// 	})

// 	// form.SetBorder(true).
// 	// 	SetTitle(" OpenSearch Installer ").
// 	// 	SetTitleAlign(tview.AlignLeft)

// 	form.SetBorder(true)
// 	form.SetTitle(" OpenSearch Installer ")

// 	// 좌우 레이아웃
// 	layout := tview.NewFlex().
// 		AddItem(form, 0, 1, true).
// 		AddItem(logView, 0, 2, false)

// 	// 실행
// 	if err := app.SetRoot(layout, true).Run(); err != nil {
// 		panic(err)
// 	}
// }

// func log(view *tview.TextView, msg string) {
// 	fmt.Fprintln(view, msg)
// }

// func runCommand(view *tview.TextView, command string) {

// 	log(view, fmt.Sprintf("[blue]$ %s", command))

// 	cmd := exec.Command("bash", "-c", command)

// 	output, err := cmd.CombinedOutput()

// 	if len(output) > 0 {
// 		lines := strings.Split(string(output), "\n")

// 		for _, line := range lines {

// 			if strings.TrimSpace(line) != "" {
// 				log(view, fmt.Sprintf("[white]%s", line))
// 			}
// 		}
// 	}

// 	if err != nil {
// 		log(view, fmt.Sprintf("[red]ERROR: %v", err))
// 	}
// }