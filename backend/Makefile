dev:
	@if [ ! -f "$$(go env GOPATH)/bin/air" ]; then \
		echo "Installing air..."; \
		go install github.com/air-verse/air@latest; \
	fi
	@$$(go env GOPATH)/bin/air
