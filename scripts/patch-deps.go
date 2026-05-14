//go:build ignore

package main

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"

	"golang.org/x/mod/semver"
)

func ensureVPrefix(v string) string {
	if v != "" && !strings.HasPrefix(v, "v") {
		return "v" + v
	}
	return v
}

func main() {
	args := os.Args[1:]
	if len(args) == 0 {
		return
	}

	for _, arg := range args {
		parts := strings.Split(arg, "@")
		if len(parts) != 2 {
			log.Fatalf("Invalid patch format: %s", arg)
		}

		pkg := parts[0]
		secureVersion := ensureVPrefix(parts[1])

		if !semver.IsValid(secureVersion) {
			log.Fatalf("Invalid semver for %s: %s", pkg, secureVersion)
		}

		// Get current version
		cmd := exec.Command("go", "list", "-m", "-f", "{{.Version}}", pkg)
		var out bytes.Buffer
		cmd.Stdout = &out

		if err := cmd.Run(); err != nil {
			continue
		}

		currentVersion := ensureVPrefix(strings.TrimSpace(out.String()))
		if currentVersion == "" {
			continue
		}

		cmp := semver.Compare(currentVersion, secureVersion)

		if cmp < 0 {
			log.Printf("Patching %s: %s -> %s", pkg, currentVersion, secureVersion)

			getCmd := exec.Command("go", "get", pkg+"@"+secureVersion)
			getCmd.Stdout = os.Stdout
			getCmd.Stderr = os.Stderr

			if err := getCmd.Run(); err != nil {
				log.Fatalf("Failed to patch %s: %v", pkg, err)
			}
		} else if cmp > 0 {
			fmt.Printf("::warning::Upstream version (%s) for %s is newer than requested patch (%s).\n", currentVersion, pkg, secureVersion)
		}
	}

	// Clean up
	tidyCmd := exec.Command("go", "mod", "tidy")
	tidyCmd.Stdout = os.Stdout
	tidyCmd.Stderr = os.Stderr
	if err := tidyCmd.Run(); err != nil {
		log.Fatalf("go mod tidy failed: %v", err)
	}
}
