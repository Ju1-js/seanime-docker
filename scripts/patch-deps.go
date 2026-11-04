//go:build ignore

package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"

	"golang.org/x/mod/semver"
)

// Fixes: CVE-2026-26014, CVE-2026-26995, CVE-2026-27141, CVE-2026-33809,
// CVE-2026-29181, CVE-2026-41178, CVE-2026-54908, CVE-2026-54909,
// CVE-2026-118264, CVE-2026-118651, CVE-2026-118653, CVE-2026-78663, and GO-2026-5932.
var patches = []struct {
	path    string
	minimum string
}{
	{"github.com/labstack/echo/v4", "v4.16.3"},
	{"github.com/pion/dtls/v3", "v3.1.4"},
	{"github.com/pion/stun/v3", "v3.1.5"},
	{"go.opentelemetry.io/otel", "v1.46.0"},
	{"github.com/refraction-networking/utls", "v1.8.2"},
	{"golang.org/x/net", "v0.62.0"},
	{"golang.org/x/crypto", "v0.58.1-0.20261009181718-2f1f834330b2"},
	{"golang.org/x/image", "v0.38.0"},
}

type module struct {
	Path    string
	Version string
	Replace *module
}

func selectedModules() map[string]module {
	cmd := exec.Command("go", "list", "-mod=readonly", "-m", "-json", "all")
	cmd.Stderr = os.Stderr
	out, err := cmd.Output()
	if err != nil {
		log.Fatalf("go list failed: %v", err)
	}

	modules := make(map[string]module)
	decoder := json.NewDecoder(bytes.NewReader(out))
	for {
		var selected module
		err := decoder.Decode(&selected)
		if err == io.EOF {
			return modules
		}
		if err != nil {
			log.Fatalf("Invalid module list: %v", err)
		}
		modules[selected.Path] = selected
	}
}

func main() {
	audit := flag.Bool("audit", false, "report upstream patch status without changing dependencies")
	flag.Parse()
	modules := selectedModules()

	if *audit {
		fmt.Println("### Go dependency patch review")
		fmt.Println()
		fmt.Println("| Module | Upstream version | Fixed minimum | Status |")
		fmt.Println("| --- | --- | --- | --- |")
	}

	var upgrades []string
	for _, patch := range patches {
		selected, present := modules[patch.path]
		version := selected.Version
		comparison := semver.Compare(version, patch.minimum)
		if *audit {
			status := "Keep"
			switch {
			case !present:
				version = "Absent"
				status = "Review for removal"
			case selected.Replace != nil:
				status = "Review replacement"
			case comparison >= 0:
				status = "Review for removal"
			}
			fmt.Printf("| %s | %s | %s | %s |\n", patch.path, version, patch.minimum, status)
			continue
		}
		if !present {
			continue
		}
		if comparison < 0 {
			log.Printf("Patching %s: %s -> %s", patch.path, version, patch.minimum)
			upgrades = append(upgrades, patch.path+"@"+patch.minimum)
		} else {
			log.Printf("Review patch for removal: %s is already at %s (minimum %s)", patch.path, version, patch.minimum)
		}
	}
	if *audit {
		return
	}

	if len(upgrades) > 0 {
		cmd := exec.Command("go", append([]string{"get"}, upgrades...)...)
		cmd.Stdout = os.Stdout
		cmd.Stderr = os.Stderr
		if err := cmd.Run(); err != nil {
			log.Fatalf("Failed to patch dependencies: %v", err)
		}
	}
	cmd := exec.Command("go", "mod", "tidy")
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("go mod tidy failed: %v", err)
	}
}
