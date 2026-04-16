.PHONY: build run tidy linux windows

# Build for current OS
build:
	go build -o bin/eupanel-agent .

# Run locally (dev mode)
run:
	AGENT_PORT=7820 AGENT_SECRET=dev-secret go run .

# Tidy dependencies
tidy:
	go mod tidy

# Cross-compile for Linux (production server)
linux:
	GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o bin/eupanel-agent-linux-amd64 .

# Cross-compile for Windows (dev/testing)
windows:
	GOOS=windows GOARCH=amd64 go build -o bin/eupanel-agent.exe .

# Install dependencies
deps:
	go get github.com/go-chi/chi/v5
	go get github.com/go-chi/cors
	go get github.com/google/uuid
	go mod tidy
