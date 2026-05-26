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

	type patchRequest struct {
		pkg           string
		secureVersion string
	}

	requestedOrder := make([]patchRequest, 0, len(args))

	for _, arg := range args {
		pkg, version, ok := strings.Cut(arg, "@")
		if !ok || pkg == "" || version == "" {
			log.Fatalf("Invalid patch format: %s", arg)
		}

		secureVersion := ensureVPrefix(version)

		if !semver.IsValid(secureVersion) {
			log.Fatalf("Invalid semver for %s: %s", pkg, secureVersion)
		}

		requestedOrder = append(requestedOrder, patchRequest{
			pkg:           pkg,
			secureVersion: secureVersion,
		})
	}

	cmd := exec.Command("go", "list", "-m", "-f", "{{.Path}}\t{{.Version}}", "all")
	var out bytes.Buffer
	cmd.Stdout = &out
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		log.Fatalf("go list failed: %v", err)
	}

	currentVersions := make(map[string]string)
	for _, line := range strings.Split(out.String(), "\n") {
		fields := strings.Fields(line)
		if len(fields) < 2 {
			continue
		}
		currentVersions[fields[0]] = ensureVPrefix(fields[1])
	}

	patched := make([]string, 0, len(requestedOrder))
	for _, request := range requestedOrder {
		pkg := request.pkg
		secureVersion := request.secureVersion

		currentVersion := currentVersions[pkg]
		if currentVersion == "" {
			continue
		}

		cmp := semver.Compare(currentVersion, secureVersion)

		if cmp < 0 {
			log.Printf("Patching %s: %s -> %s", pkg, currentVersion, secureVersion)
			patched = append(patched, pkg+"@"+secureVersion)
		} else if cmp > 0 {
			fmt.Printf("::warning::Upstream version (%s) for %s is newer than requested patch (%s).\n", currentVersion, pkg, secureVersion)
		}
	}

	if len(patched) > 0 {
		getCmd := exec.Command("go", append([]string{"get"}, patched...)...)
		getCmd.Stdout = os.Stdout
		getCmd.Stderr = os.Stderr

		if err := getCmd.Run(); err != nil {
			log.Fatalf("Failed to patch dependencies: %v", err)
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
