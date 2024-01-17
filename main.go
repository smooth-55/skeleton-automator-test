package automator

import (
	"fmt"
	"os/exec"
)

func CreateApp() {
	cmd := exec.Command("bash", "automate/scripts/new_app.sh")
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Error:", err)
	}
	fmt.Println(string(output))
}

func InjectAuth() {
	cmd := exec.Command("bash", "automate/scripts/inject_auth.sh")
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Error:", err)
	}
	fmt.Println(string(output))
}
