#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE_TAG="vercel-rust-cli:test"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is running
check_docker() {
    log_info "Checking Docker availability..."
    
    if ! command -v docker >/dev/null 2>&1; then
        log_error "Docker is not installed"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running"
        return 1
    fi
    
    local docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    log_success "Docker $docker_version is running"
    return 0
}

# Build Docker image
build_docker_image() {
    log_info "Building Docker image for Rust CLI..."
    
    cd "$ROOT_DIR"
    
    # Clean up any existing test image
    docker rmi "$IMAGE_TAG" >/dev/null 2>&1 || true
    
    # Build the image
    if DOCKER_BUILDKIT=1 docker build -f "$ROOT_DIR/docker/cli.Dockerfile" -t "$IMAGE_TAG" "$ROOT_DIR"; then
        log_success "Docker image built successfully"
        return 0
    else
        log_error "Failed to build Docker image"
        return 1
    fi
}

# Test the binary in Docker
test_binary_in_docker() {
    log_info "Testing Rust CLI binary in Docker container..."
    
    # Test ping functionality
    local ping_test='{"ping": true, "timestamp": "2024-01-01T00:00:00Z"}'
    log_info "Testing ping functionality..."
    
    local ping_result=$(echo "$ping_test" | docker run --rm -i "$IMAGE_TAG" /cli)
    
    if echo "$ping_result" | grep -q '"pong":true'; then
        log_success "Ping test passed: $ping_result"
    else
        log_error "Ping test failed: $ping_result"
        return 1
    fi
    
    # Test echo functionality
    local echo_test='{"message": "Hello from Docker!"}'
    log_info "Testing echo functionality..."
    
    local echo_result=$(echo "$echo_test" | docker run --rm -i "$IMAGE_TAG" /cli)
    
    if echo "$echo_result" | grep -q '"response":"Echo: Hello from Docker!"'; then
        log_success "Echo test passed: $echo_result"
    else
        log_error "Echo test failed: $echo_result"
        return 1
    fi
    
    # Test empty input
    log_info "Testing empty input handling..."
    
    local empty_result=$(echo "" | docker run --rm -i "$IMAGE_TAG" /cli)
    
    if echo "$empty_result" | grep -q '"ok":true'; then
        log_success "Empty input test passed: $empty_result"
    else
        log_error "Empty input test failed: $empty_result"
        return 1
    fi
    
    return 0
}

# Validate binary properties
validate_binary_properties() {
    log_info "Validating binary properties..."
    
    # Extract binary from container
    local temp_container=$(docker create "$IMAGE_TAG" /bin/sh)
    local temp_binary="/tmp/test_cli_binary"
    
    docker cp "$temp_container:/cli" "$temp_binary"
    docker rm "$temp_container" >/dev/null
    
    # Check binary properties
    local file_info=$(file "$temp_binary" 2>/dev/null || echo "")
    
    if [[ "$file_info" == *"ELF"* ]]; then
        log_success "Binary is Linux ELF executable"
    else
        log_error "Binary is not a Linux ELF executable: $file_info"
        rm -f "$temp_binary"
        return 1
    fi
    
    if [[ "$file_info" == *"statically linked"* ]]; then
        log_success "Binary is statically linked (good for Vercel)"
    else
        log_warning "Binary is not statically linked: $file_info"
    fi
    
    if [[ "$file_info" == *"x86-64"* ]]; then
        log_success "Binary is x86-64 architecture (compatible with Vercel)"
    else
        log_error "Binary architecture not compatible: $file_info"
        rm -f "$temp_binary"
        return 1
    fi
    
    # Check binary size
    local binary_size=$(stat -f%z "$temp_binary" 2>/dev/null || stat -c%s "$temp_binary" 2>/dev/null)
    log_info "Binary size: $binary_size bytes"
    
    if [[ $binary_size -lt 10000000 ]]; then
        log_success "Binary size is reasonable for Vercel deployment"
    else
        log_warning "Binary size is quite large: $binary_size bytes"
    fi
    
    rm -f "$temp_binary"
    return 0
}

# Test Docker build process
test_docker_build_process() {
    log_info "Testing Docker build process..."
    
    cd "$ROOT_DIR"
    
    # Run the actual Docker build script
    if bash scripts/build-cli-docker.sh; then
        log_success "Docker build script executed successfully"
        
        # Check if binary was created
        if [[ -f "api/bin/cli" ]]; then
            log_success "Binary was extracted to api/bin/cli"
            
            # Check binary properties
            local file_info=$(file "api/bin/cli" 2>/dev/null || echo "")
            log_info "Extracted binary info: $file_info"
            
            return 0
        else
            log_error "Binary was not extracted to api/bin/cli"
            return 1
        fi
    else
        log_error "Docker build script failed"
        return 1
    fi
}

# Main validation function
main() {
    log_info "Starting Docker Rust build validation..."
    log_info "Project root: $ROOT_DIR"
    
    local failed_tests=0
    
    # Check Docker availability
    if ! check_docker; then
        ((failed_tests++))
    fi
    
    # Build Docker image
    if ! build_docker_image; then
        ((failed_tests++))
    fi
    
    # Test binary functionality
    if ! test_binary_in_docker; then
        ((failed_tests++))
    fi
    
    # Validate binary properties
    if ! validate_binary_properties; then
        ((failed_tests++))
    fi
    
    # Test the actual build process
    if ! test_docker_build_process; then
        ((failed_tests++))
    fi
    
    if [[ $failed_tests -gt 0 ]]; then
        log_error "$failed_tests validation tests failed"
        exit 1
    fi
    
    log_success "=== All Docker Rust Build Validations Passed ==="
    log_info "✅ Docker image builds successfully"
    log_info "✅ Rust CLI binary works correctly in Docker"
    log_info "✅ Binary is Linux ELF executable (compatible with Vercel)"
    log_info "✅ Binary handles ping, echo, and empty input correctly"
    log_info "✅ Docker build script extracts binary properly"
    
    # Clean up test image
    docker rmi "$IMAGE_TAG" >/dev/null 2>&1 || true
}

# Run main function
main "$@"
