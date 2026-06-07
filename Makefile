.PHONY: build-test-images test test-ubuntu test-fedora test-arch test-powershell help

# Build all pre-built Docker images for testing (rebuilds even if cached)
build-test-images:
	@echo "Building test images..."
	docker build --build-arg DISTRO=ubuntu:24.04 -t ocw-test:ubuntu -f tests/Dockerfile.test .
	docker build --build-arg DISTRO=fedora:40 -t ocw-test:fedora -f tests/Dockerfile.test .
	docker build --build-arg DISTRO=archlinux:latest -t ocw-test:arch -f tests/Dockerfile.test .
	@echo "All test images built successfully."

# Run individual Linux distro tests (uses pre-built image, builds if missing)
test-ubuntu:
	./tests/run_tests.sh ubuntu

test-fedora:
	./tests/run_tests.sh fedora

test-arch:
	./tests/run_tests.sh arch

test-powershell:
	./tests/run_tests.sh powershell

# Run all tests (sequential, for CI)
test: build-test-images
	./tests/run_tests.sh

help:
	@echo "Available targets:"
	@echo "  make build-test-images  - Build all 3 pre-built Docker images"
	@echo "  make test-ubuntu        - Run Ubuntu test"
	@echo "  make test-fedora        - Run Fedora test"
	@echo "  make test-arch          - Run Arch test"
	@echo "  make test-powershell    - Run PowerShell syntax check"
	@echo "  make test               - Build images and run all tests"
