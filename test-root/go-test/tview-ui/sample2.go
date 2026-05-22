package main

import (
	"fmt"
	"os/exec"
	"strings"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

func main() {

	app := tview.NewApplication()

	// ===== 전체 색상 테마 =====

	tview.Styles.PrimitiveBackgroundColor = tcell.ColorBlack
	tview.Styles.ContrastBackgroundColor = tcell.ColorBlue
	tview.Styles.MoreContrastBackgroundColor = tcell.ColorDarkCyan

	tview.Styles.BorderColor = tcell.ColorWhite

	tview.Styles.TitleColor = tcell.ColorGreen
	tview.Styles.GraphicsColor = tcell.ColorGreen

	tview.Styles.PrimaryTextColor = tcell.ColorWhite
	tview.Styles.SecondaryTextColor = tcell.ColorYellow

	// ===== 로그 창 =====

	logView := tview.NewTextView()

	logView.SetDynamicColors(true)
	logView.SetScrollable(true)
	logView.SetChangedFunc(func() {
		app.Draw()
	})

	logView.SetBorder(true)
	logView.SetTitle(" Logs ")

	fmt.Fprintln(logView, "[green]installer started...")
	fmt.Fprintln(logView, "[yellow]checking system...")

	// ===== Form =====

	form := tview.NewForm()

	var installType string = "Single"

	form.AddDropDown(
		"Install Type",
		[]string{
			"Single",
			"Cluster",
		},
		0,
		func(option string, index int) {
			installType = option
		},
	)

	form.AddInputField(
		"HTTP Port",
		"9200",
		10,
		nil,
		nil,
	)

	form.AddInputField(
		"Install Path",
		"/opt/opensearch",
		30,
		nil,
		nil,
	)

	form.AddCheckbox(
		"Install Dashboard",
		true,
		nil,
	)

	// ===== Install 버튼 =====

	form.AddButton("Install", func() {

		port := form.GetFormItem(1).
			(*tview.InputField).
			GetText()

		path := form.GetFormItem(2).
			(*tview.InputField).
			GetText()

		log(logView, "[green]===================================")
		log(logView, "[green]Install Started")
		log(logView, fmt.Sprintf(
			"[white]Type : %s",
			installType,
		))
		log(logView, fmt.Sprintf(
			"[white]Port : %s",
			port,
		))
		log(logView, fmt.Sprintf(
			"[white]Path : %s",
			path,
		))

		runCommand(logView,
			"echo Installing OpenSearch")

		runCommand(logView,
			"sleep 1")

		runCommand(logView,
			"echo Creating Config")

		runCommand(logView,
			"sleep 1")

		runCommand(logView,
			"echo Starting Service")

		runCommand(logView,
			"sleep 1")

		runCommand(logView,
			"echo Health Check OK")

		log(logView,
			"[green]Install Complete")
	})

	// ===== Quit 버튼 =====

	form.AddButton("Quit", func() {
		app.Stop()
	})

	form.SetBorder(true)
	form.SetTitle(" OpenSearch Installer ")

	// 버튼 색상
	form.SetButtonBackgroundColor(
		tcell.ColorDarkCyan,
	)

	form.SetButtonTextColor(
		tcell.ColorWhite,
	)

	// ===== Layout =====

	mainFlex := tview.NewFlex().
		SetDirection(tview.FlexRow).
		AddItem(form, 15, 1, true).
		AddItem(logView, 0, 1, false)

	// ===== 실행 =====

	if err := app.SetRoot(
		mainFlex,
		true,
	).Run(); err != nil {

		panic(err)
	}
}

func log(
	view *tview.TextView,
	msg string,
) {
	fmt.Fprintln(view, msg)
}

func runCommand(
	view *tview.TextView,
	command string,
) {

	log(view,
		fmt.Sprintf(
			"[blue]$ %s",
			command,
		))

	cmd := exec.Command(
		"bash",
		"-c",
		command,
	)

	output, err := cmd.CombinedOutput()

	if len(output) > 0 {

		lines := strings.Split(
			string(output),
			"\n",
		)

		for _, line := range lines {

			if strings.TrimSpace(line) != "" {

				log(view,
					fmt.Sprintf(
						"[white]%s",
						line,
					))
			}
		}
	}

	if err != nil {

		log(view,
			fmt.Sprintf(
				"[red]ERROR: %v",
				err,
			))
	}
}