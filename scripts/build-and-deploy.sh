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
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [--verbose] [--help]"
            echo "  --verbose, -v    Enable verbose output"
            echo "  --help, -h      Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

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

log_verbose() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo -e "${BLUE}[VERBOSE]${NC} $1"
    fi
}

# OS Detection
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
log_info "Detected OS: $OS"

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check Node.js version
check_nodejs() {
    log_info "Checking Node.js installation..."
    
    if ! command_exists node; then
        log_error "Node.js is not installed. Please install Node.js 22.x"
        if [[ "$OS" == "macos" ]]; then
            log_info "Run: brew install node@22"
        elif [[ "$OS" == "linux" ]]; then
            log_info "Run: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs"
        fi
        return 1
    fi
    
    local node_version=$(node --version | sed 's/v//')
    local major_version=$(echo "$node_version" | cut -d. -f1)
    
    if [[ "$major_version" != "22" ]]; then
        log_error "Node.js version $node_version detected. Required: 22.x"
        return 1
    fi
    
    log_success "Node.js $node_version is installed"
    return 0
}

# Check npm
check_npm() {
    log_info "Checking npm installation..."
    
    if ! command_exists npm; then
        log_error "npm is not installed"
        return 1
    fi
    
    local npm_version=$(npm --version)
    log_success "npm $npm_version is installed"
    return 0
}

# Check Git
check_git() {
    log_info "Checking Git installation..."
    
    if ! command_exists git; then
        log_error "Git is not installed. Required for Vercel CLI authentication"
        if [[ "$OS" == "macos" ]]; then
            log_info "Run: brew install git"
        elif [[ "$OS" == "linux" ]]; then
            log_info "Run: sudo apt install git"
        fi
        return 1
    fi
    
    local git_version=$(git --version | cut -d' ' -f3)
    log_success "Git $git_version is installed"
    return 0
}

# Check Rust installation
check_rust() {
    log_info "Checking Rust installation..."
    
    if ! command_exists rustc; then
        log_error "Rust is not installed"
        log_info "Run: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        return 1
    fi
    
    local rust_version=$(rustc --version | cut -d' ' -f2)
    log_success "Rust $rust_version is installed"
    
    # Check if rustup is available
    if ! command_exists rustup; then
        log_error "rustup is not available"
        return 1
    fi
    
    return 0
}

# Check cross-compilation tools
check_cross_compilation() {
    log_info "Checking cross-compilation tools..."
    
    local has_zig=false
    local has_cross=false
    
    # Check for cargo-zigbuild in PATH or asdf Rust installation
    local zigbuild_path=""
    if command_exists cargo-zigbuild; then
        zigbuild_path=$(which cargo-zigbuild)
        log_success "cargo-zigbuild is available at $zigbuild_path"
        has_zig=true
    else
        # Check asdf Rust installation
        local rust_home=$(rustup show home 2>/dev/null || echo "")
        if [[ -n "$rust_home" && -f "$rust_home/bin/cargo-zigbuild" ]]; then
            zigbuild_path="$rust_home/bin/cargo-zigbuild"
            log_success "cargo-zigbuild found in asdf Rust installation at $zigbuild_path"
            has_zig=true
        else
            log_warning "cargo-zigbuild not found"
        fi
    fi
    
    if command_exists zig; then
        log_success "Zig is available"
    else
        log_warning "Zig not found"
    fi
    
    if command_exists cross; then
        log_success "cross is available"
        has_cross=true
    else
        log_warning "cross not found"
    fi
    
    if [[ "$has_zig" == "true" ]] || [[ "$has_cross" == "true" ]]; then
        return 0
    else
        log_error "No cross-compilation tools found"
        log_info "Install one of:"
        log_info "  - cargo-zigbuild + zig (recommended)"
        log_info "  - cross"
        return 1
    fi
}

# Check Docker
check_docker() {
    log_info "Checking Docker installation..."
    
    if ! command_exists docker; then
        log_warning "Docker is not installed (optional for local Rust builds)"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_warning "Docker is installed but not running"
        return 1
    fi
    
    local docker_version=$(docker --version | cut -d' ' -f3 | sed 's/,//')
    log_success "Docker $docker_version is installed and running"
    return 0
}

# Check Vercel CLI
check_vercel() {
    log_info "Checking Vercel CLI installation..."
    
    if ! command_exists vercel; then
        log_error "Vercel CLI is not installed"
        log_info "Run: npm install -g vercel"
        return 1
    fi
    
    local vercel_version=$(vercel --version | cut -d' ' -f2)
    log_success "Vercel CLI $vercel_version is installed"
    
    # Check if user is logged in
    if ! vercel whoami >/dev/null 2>&1; then
        log_error "Not logged in to Vercel. Please run: vercel login"
        return 1
    fi
    
    local vercel_user=$(vercel whoami)
    log_success "Logged in to Vercel as: $vercel_user"
    return 0
}

# Install npm dependencies
install_dependencies() {
    log_info "Installing npm dependencies..."
    
    cd "$ROOT_DIR"
    
    if [[ "$VERBOSE" == "true" ]]; then
        npm install
    else
        npm install --silent
    fi
    
    log_success "npm dependencies installed"
}

# Build Rust CLI
build_rust_cli() {
    log_info "Building Rust CLI..."
    
    cd "$ROOT_DIR"
    
    # Check for cargo-zigbuild in PATH or asdf Rust installation
    local zigbuild_path=""
    if command_exists cargo-zigbuild; then
        zigbuild_path=$(which cargo-zigbuild)
    else
        local rust_home=$(rustup show home 2>/dev/null || echo "")
        if [[ -n "$rust_home" && -f "$rust_home/bin/cargo-zigbuild" ]]; then
            zigbuild_path="$rust_home/bin/cargo-zigbuild"
        fi
    fi
    
    # Try local build first
    if [[ -n "$zigbuild_path" ]] && command_exists zig; then
        log_info "Building with cargo-zigbuild at $zigbuild_path..."
        if [[ "$VERBOSE" == "true" ]]; then
            npm run build:cli
        else
            npm run build:cli >/dev/null 2>&1
        fi
        log_success "Rust CLI built with cargo-zigbuild"
        return 0
    fi
    
    # Try cross
    if command_exists cross; then
        log_info "Building with cross..."
        if [[ "$VERBOSE" == "true" ]]; then
            npm run build:cli
        else
            npm run build:cli >/dev/null 2>&1
        fi
        log_success "Rust CLI built with cross"
        return 0
    fi
    
    # Fall back to Docker
    if command_exists docker && docker info >/dev/null 2>&1; then
        log_info "Building with Docker..."
        if [[ "$VERBOSE" == "true" ]]; then
            npm run build:cli:docker
        else
            npm run build:cli:docker >/dev/null 2>&1
        fi
        log_success "Rust CLI built with Docker"
        return 0
    fi
    
    log_error "Failed to build Rust CLI - no suitable build method available"
    return 1
}

# Validate binary
validate_binary() {
    log_info "Validating compiled binary..."
    
    local binary_path="$ROOT_DIR/api/bin/cli"
    
    if [[ ! -f "$binary_path" ]]; then
        log_error "Binary not found at $binary_path"
        return 1
    fi
    
    if [[ ! -x "$binary_path" ]]; then
        log_error "Binary is not executable"
        return 1
    fi
    
    # Check if it's a Linux binary (expected for Vercel deployment)
    local file_type=$(file "$binary_path" 2>/dev/null || echo "")
    if [[ "$file_type" == *"ELF"* ]]; then
        log_success "Linux ELF binary validated (ready for Vercel deployment)"
        return 0
    fi
    
    # For native binaries, test if they can run
    if ! "$binary_path" --help >/dev/null 2>&1; then
        log_error "Binary failed to run"
        return 1
    fi
    
    log_success "Binary validated successfully"
    return 0
}

# Build Next.js application
build_nextjs() {
    log_info "Building Next.js application..."
    
    cd "$ROOT_DIR"
    
    if [[ "$VERBOSE" == "true" ]]; then
        npm run build
    else
        npm run build >/dev/null 2>&1
    fi
    
    log_success "Next.js application built"
}

# Deploy to Vercel
deploy_to_vercel() {
    log_info "Deploying to Vercel..."
    
    cd "$ROOT_DIR"
    
    if [[ "$VERBOSE" == "true" ]]; then
        vercel --prod
    else
        vercel --prod >/dev/null 2>&1
    fi
    
    log_success "Deployed to Vercel successfully"
}

# Main execution
main() {
    log_info "Starting build and deployment process..."
    log_info "Project root: $ROOT_DIR"
    
    # Prerequisites validation
    log_info "=== Validating Prerequisites ==="
    
    local failed_checks=0
    
    if ! check_nodejs; then
        ((failed_checks++))
    fi
    
    if ! check_npm; then
        ((failed_checks++))
    fi
    
    if ! check_git; then
        ((failed_checks++))
    fi
    
    if ! check_rust; then
        ((failed_checks++))
    fi
    
    if ! check_cross_compilation; then
        ((failed_checks++))
    fi
    
    if ! check_docker; then
        log_warning "Docker check failed - will use local Rust build"
    fi
    
    if ! check_vercel; then
        ((failed_checks++))
    fi
    
    if [[ $failed_checks -gt 0 ]]; then
        log_error "$failed_checks prerequisite checks failed"
        log_error "Please install missing dependencies and try again"
        exit 1
    fi
    
    log_success "All prerequisites validated"
    
    # Build process
    log_info "=== Building Project ==="
    
    if ! install_dependencies; then
        log_error "Failed to install dependencies"
        exit 1
    fi
    
    if ! build_rust_cli; then
        log_error "Failed to build Rust CLI"
        exit 1
    fi
    
    if ! validate_binary; then
        log_error "Binary validation failed"
        exit 1
    fi
    
    if ! build_nextjs; then
        log_error "Failed to build Next.js application"
        exit 1
    fi
    
    log_success "Project built successfully"
    
    # Deployment
    log_info "=== Deploying to Vercel ==="
    
    if ! deploy_to_vercel; then
        log_error "Failed to deploy to Vercel"
        exit 1
    fi
    
    log_success "=== Build and Deployment Complete ==="
    log_info "Your application has been successfully built and deployed to Vercel!"
}

# Run main function
main "$@"
