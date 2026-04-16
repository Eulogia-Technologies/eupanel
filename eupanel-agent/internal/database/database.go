package database

import (
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"os/exec"
	"strings"
)

type DBInfo struct {
	Name     string `json:"name"`
	User     string `json:"user"`
	Password string `json:"password,omitempty"`
	SizeBytes int64 `json:"size_bytes"`
}

// Create creates a MySQL database + dedicated user with full privileges.
func Create(dbName, dbUser, dbPass string) error {
	if dbPass == "" {
		dbPass = randomPassword()
	}

	queries := []string{
		fmt.Sprintf("CREATE DATABASE IF NOT EXISTS `%s` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;", dbName),
		fmt.Sprintf("CREATE USER IF NOT EXISTS '%s'@'localhost' IDENTIFIED BY '%s';", dbUser, dbPass),
		fmt.Sprintf("GRANT ALL PRIVILEGES ON `%s`.* TO '%s'@'localhost';", dbName, dbUser),
		"FLUSH PRIVILEGES;",
	}

	sql := strings.Join(queries, "\n")
	cmd := exec.Command("mysql", "-u", "root", "-e", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("mysql create failed: %s — %w", string(out), err)
	}
	return nil
}

// Delete drops a MySQL database and its dedicated user.
func Delete(dbName, dbUser string) error {
	queries := []string{
		fmt.Sprintf("DROP DATABASE IF EXISTS `%s`;", dbName),
		fmt.Sprintf("DROP USER IF EXISTS '%s'@'localhost';", dbUser),
		"FLUSH PRIVILEGES;",
	}

	sql := strings.Join(queries, "\n")
	cmd := exec.Command("mysql", "-u", "root", "-e", sql)
	out, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("mysql delete failed: %s — %w", string(out), err)
	}
	return nil
}

// List returns all non-system databases.
func List() ([]DBInfo, error) {
	out, err := exec.Command("mysql", "-u", "root", "-sN",
		"-e", "SHOW DATABASES;").Output()
	if err != nil {
		return nil, fmt.Errorf("mysql list failed: %w", err)
	}

	system := map[string]bool{
		"information_schema": true,
		"performance_schema": true,
		"mysql":              true,
		"sys":                true,
	}

	var dbs []DBInfo
	for _, name := range strings.Split(strings.TrimSpace(string(out)), "\n") {
		name = strings.TrimSpace(name)
		if name == "" || system[name] {
			continue
		}
		dbs = append(dbs, DBInfo{Name: name})
	}
	return dbs, nil
}

// SizeOf returns the size of a database in bytes.
func SizeOf(dbName string) (int64, error) {
	query := fmt.Sprintf(
		"SELECT SUM(data_length + index_length) FROM information_schema.tables WHERE table_schema='%s';",
		dbName,
	)
	out, err := exec.Command("mysql", "-u", "root", "-sN", "-e", query).Output()
	if err != nil {
		return 0, err
	}

	var size int64
	fmt.Sscanf(strings.TrimSpace(string(out)), "%d", &size)
	return size, nil
}

func randomPassword() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}
