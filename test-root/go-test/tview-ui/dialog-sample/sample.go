package main

import (
	"fmt"
	"os/exec"
	"strings"
)

func main() {

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

	if err != nil {
		fmt.Println("cancel or error:", err)
		return
	}

	values := strings.Split(
		strings.TrimSpace(string(output)),
		"\n",
	)

	fmt.Println("PORT :", values[0])
	fmt.Println("PATH :", values[1])
}