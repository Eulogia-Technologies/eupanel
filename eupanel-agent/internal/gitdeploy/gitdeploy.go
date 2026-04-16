package gitdeploy

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

type DeployResult struct {
	Log     string `json:"log"`
	Cloned  bool   `json:"cloned"` // true = fresh clone, false = pull
	Commits int    `json:"commits"` // number of new commits pulled
}

// Deploy clones the repo if deploy_path is empty, or pulls if it already exists.
// It always checks out the specified branch.
func Deploy(repoURL, branch, deployPath string) (*DeployResult, error) {
	if repoURL == "" || branch == "" || deployPath == "" {
		return nil, fmt.Errorf("repo_url, branch, and deploy_path are all required")
	}

	// Sanitise branch name — must not contain shell-special characters
	if !isSafeBranch(branch) {
		return nil, fmt.Errorf("invalid branch name: %q", branch)
	}

	// Ensure deploy path's parent exists
	if err := os.MkdirAll(filepath.Dir(deployPath), 0755); err != nil {
		return nil, fmt.Errorf("cannot create parent directory: %w", err)
	}

	gitDir := filepath.Join(deployPath, ".git")
	_, err := os.Stat(gitDir)
	alreadyCloned := err == nil

	var logs []string
	var cloned bool

	if !alreadyCloned {
		// ── Fresh clone ──────────────────────────────────────────────────────
		logs = append(logs, fmt.Sprintf("Cloning %s (branch: %s) into %s", repoURL, branch, deployPath))
		out, err := run("git", "clone",
			"--branch", branch,
			"--single-branch",
			"--depth", "1",
			repoURL, deployPath,
		)
		logs = append(logs, out)
		if err != nil {
			return nil, fmt.Errorf("git clone failed: %s — %w", out, err)
		}
		cloned = true
	} else {
		// ── Pull latest ──────────────────────────────────────────────────────
		logs = append(logs, fmt.Sprintf("Pulling latest from origin/%s in %s", branch, deployPath))

		// Fetch
		out, err := runIn(deployPath, "git", "fetch", "origin", branch)
		logs = append(logs, out)
		if err != nil {
			return nil, fmt.Errorf("git fetch failed: %s — %w", out, err)
		}

		// Checkout branch (handles branch switch if needed)
		out, err = runIn(deployPath, "git", "checkout", branch)
		logs = append(logs, out)
		if err != nil {
			// May already be on this branch — not necessarily an error
			logs = append(logs, fmt.Sprintf("checkout note: %s", out))
		}

		// Reset to remote — discard any local changes
		out, err = runIn(deployPath, "git", "reset", "--hard", "origin/"+branch)
		logs = append(logs, out)
		if err != nil {
			return nil, fmt.Errorf("git reset failed: %s — %w", out, err)
		}

		// Clean untracked files
		out, _ = runIn(deployPath, "git", "clean", "-fd")
		logs = append(logs, out)
	}

	// Fix ownership so www-data / the system user can read files
	out, _ := run("chown", "-R", "www-data:www-data", deployPath)
	if out != "" {
		logs = append(logs, out)
	}

	return &DeployResult{
		Log:    strings.Join(logs, "\n"),
		Cloned: cloned,
	}, nil
}

// ── Helpers ───────────────────────────────────────────────────────────────────

func run(name string, args ...string) (string, error) {
	out, err := exec.Command(name, args...).CombinedOutput()
	return strings.TrimSpace(string(out)), err
}

func runIn(dir, name string, args ...string) (string, error) {
	cmd := exec.Command(name, args...)
	cmd.Dir = dir
	out, err := cmd.CombinedOutput()
	return strings.TrimSpace(string(out)), err
}

// isSafeBranch ensures the branch name only contains safe characters.
func isSafeBranch(branch string) bool {
	if len(branch) == 0 || len(branch) > 100 {
		return false
	}
	for _, c := range branch {
		if !((c >= 'a' && c <= 'z') ||
			(c >= 'A' && c <= 'Z') ||
			(c >= '0' && c <= '9') ||
			c == '-' || c == '_' || c == '.' || c == '/') {
			return false
		}
	}
	return true
}
