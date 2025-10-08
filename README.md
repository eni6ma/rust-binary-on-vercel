# Vercel Rust Template

A minimal Next.js + Rust CLI template for Vercel deployment with ping functionality.

## Features

- **Next.js Frontend**: Clean, minimal React interface with Tailwind CSS
- **Rust CLI Binary**: Processes JSON input and returns structured responses
- **Ping Functionality**: Built-in ping/pong testing between frontend and Rust binary
- **Docker Support**: Local compilation using Docker for cross-platform builds
- **Vercel Ready**: Configured for seamless Vercel deployment
- **Automated Build & Deploy**: Single script for complete build and deployment pipeline

## Prerequisites

### Required for Local Development & Deployment

#### Core Dependencies
- **Node.js**: Version 22.x (as specified in package.json engines)
- **Package Manager**: Choose one:
  - **npm**: Comes with Node.js (default)
  - **yarn**: Alternative package manager (recommended for faster installs)
- **Git**: For version control and Vercel CLI authentication

#### For Rust CLI Compilation (Choose One Option)

**Option A: Local Rust Toolchain (Recommended for Development)**
- **Rust**: Latest stable version via rustup
- **Cross-compilation tools** (choose one):
  - **cargo-zigbuild** + **Zig**: For macOS/Linux cross-compilation
  - **cross**: Alternative cross-compilation tool

**Option B: Docker (No Local Rust Required)**
- **Docker**: For containerized builds
- **Docker BuildKit**: Enabled for optimized builds

#### For Vercel Deployment
- **Vercel CLI**: For deployment automation
- **Vercel Account**: With project linked
- **Environment Variables**: Any required secrets/API keys

### Platform-Specific Installation

#### macOS (OSX)
```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Node.js (via Homebrew)
brew install node@22

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install cross-compilation tools (choose one)
# Option 1: cargo-zigbuild + Zig (recommended)
cargo install cargo-zigbuild
brew install zig

# Option 2: cross
cargo install cross --git https://github.com/cross-rs/cross

# Install Docker (if using Docker option)
brew install --cask docker

# Install Vercel CLI
npm install -g vercel
# or with yarn
yarn global add vercel
```

#### Linux (Ubuntu/Debian)
```bash
# Update package manager
sudo apt update

# Install Node.js 22.x
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install cross-compilation tools (choose one)
# Option 1: cargo-zigbuild + Zig
cargo install cargo-zigbuild
sudo apt install zig

# Option 2: cross
cargo install cross --git https://github.com/cross-rs/cross

# Install Docker (if using Docker option)
sudo apt install docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Install Vercel CLI
sudo npm install -g vercel
# or with yarn
sudo yarn global add vercel
```

## Package Manager: npm vs yarn

This project supports both **npm** and **yarn** package managers. Choose based on your preference:

### npm (Default)
- **Pros**: Comes with Node.js, widely supported, stable
- **Cons**: Slower installs, larger lock files
- **Usage**: `npm install`, `npm run <script>`

### yarn (Recommended)
- **Pros**: Faster installs, better dependency resolution, smaller lock files
- **Cons**: Additional installation step
- **Usage**: `yarn install`, `yarn <script>`

### Installing yarn
```bash
# Install yarn globally
npm install -g yarn
# or via Homebrew (macOS)
brew install yarn
# or via apt (Linux)
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt update && sudo apt install yarn
```

## Quick Start

### Automated Build & Deploy (Recommended)

**Using npm:**
```bash
# Single command for complete build and deployment
npm run build:deploy
```

**Using yarn:**
```bash
# Single command for complete build and deployment
yarn run build:deploy
```

**Direct script execution:**
```bash
# Make the script executable (first time only)
chmod +x scripts/build-and-deploy.sh

# Run complete build and deployment
./scripts/build-and-deploy.sh
```

### Manual Development Workflow

1. **Install dependencies**:
   ```bash
   # Using npm
   npm install
   
   # Using yarn
   yarn install
   ```

2. **Build the Rust CLI locally** (requires Rust toolchain):
   ```bash
   # Using npm
   npm run build:cli
   
   # Using yarn
   yarn run build:cli
   ```

3. **Or build using Docker** (no local Rust required):
   ```bash
   # Using npm
   npm run build:cli:docker
   
   # Using yarn
   yarn run build:cli:docker
   ```

4. **Start development server**:
   ```bash
   # Using npm
   npm run dev
   
   # Using yarn
   yarn dev
   ```

5. **Build for production**:
   ```bash
   # Using npm
   npm run build
   
   # Using yarn
   yarn build
   ```

6. **Deploy to Vercel**:
   ```bash
   vercel --prod
   ```

## How it Works

### Ping Test
- Click "Ping Rust Binary" to test the connection
- Sends a structured ping message with timestamp
- Rust binary responds with pong confirmation

### Custom Messages
- Enter a custom message in the text area
- Click "Send Custom Message" to process it
- Message is sent to Rust CLI binary via `/api/proxy` endpoint
- Rust binary processes input and returns JSON response

### Architecture
- **Frontend**: Next.js with React hooks for state management
- **API**: `/api/proxy.js` spawns Rust binary and handles I/O
- **Rust CLI**: Processes JSON input, handles ping/pong, echoes messages
- **Deployment**: Vercel functions with binary included in deployment

## Local Development Setup

### Option 1: Local Rust Toolchain
```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Install cargo-zigbuild (recommended)
cargo install cargo-zigbuild
brew install zig  # macOS

# Build CLI
# Using npm
npm run build:cli
# Using yarn
yarn run build:cli
```

### Option 2: Docker (No Local Rust Required)
```bash
# Just need Docker running
# Using npm
npm run build:cli:docker
# Using yarn
yarn run build:cli:docker
```

## Deployment

1. **Build the CLI binary**:
   ```bash
   # Using npm
   npm run build:cli:docker
   
   # Using yarn
   yarn run build:cli:docker
   ```

2. **Deploy to Vercel**:
   ```bash
   vercel --prod
   ```

The binary will be automatically included in the Vercel function deployment.

## yarn run build:deploy - Complete Guide

The `yarn run build:deploy` command is a comprehensive automation script that handles the entire build and deployment pipeline. Here's everything you need to know:

### What it does
1. **Validates Prerequisites**: Checks for Node.js, yarn, Git, Rust toolchain, Docker, and Vercel CLI
2. **Installs Dependencies**: Runs `yarn install` to install all Node.js dependencies
3. **Builds Rust CLI**: Compiles the Rust binary using the best available method
4. **Builds Next.js App**: Compiles the frontend for production
5. **Validates Build**: Ensures all components are properly built
6. **Deploys to Vercel**: Pushes the complete application to production

### Prerequisites
Before running `yarn run build:deploy`, ensure you have:

- **Node.js 22.x**: `node --version`
- **yarn**: `yarn --version`
- **Git**: `git --version`
- **Rust toolchain** (for local builds): `rustc --version`
- **Docker** (for Docker builds): `docker --version`
- **Vercel CLI**: `vercel --version`
- **Vercel Authentication**: `vercel whoami`

### Usage Examples

**Basic deployment:**
```bash
yarn run build:deploy
```

**Verbose output (recommended for debugging):**
```bash
yarn run build:deploy:verbose
```

**Step-by-step process:**
```bash
# 1. Install dependencies
yarn install

# 2. Build Rust CLI (choose one)
yarn run build:cli          # Local Rust toolchain
yarn run build:cli:docker   # Docker build

# 3. Build Next.js app
yarn build

# 4. Deploy to Vercel
vercel --prod
```

### Troubleshooting yarn run build:deploy

**Common Issues:**

1. **yarn not found:**
   ```bash
   # Install yarn globally
   npm install -g yarn
   ```

2. **Vercel not authenticated:**
   ```bash
   vercel login
   vercel whoami  # Verify authentication
   ```

3. **Rust toolchain missing:**
   ```bash
   # Install Rust
   curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
   source ~/.cargo/env
   ```

4. **Docker not running:**
   ```bash
   # Start Docker service
   brew services start docker  # macOS
   sudo systemctl start docker  # Linux
   ```

5. **Permission issues:**
   ```bash
   # Fix script permissions
   chmod +x scripts/build-and-deploy.sh
   ```

### Environment Variables
The script automatically handles:
- Node.js environment detection
- Rust toolchain detection
- Docker availability
- Vercel authentication status

### Output
The script provides:
- ✅ Success indicators for each step
- ❌ Error messages with troubleshooting hints
- 📊 Build statistics and timing
- 🔗 Deployment URL upon completion

## Automated Build & Deploy Script

The `scripts/build-and-deploy.sh` script provides a complete automation pipeline that:

### Prerequisites Validation
- ✅ **Node.js**: Checks for Node.js 22.x installation
- ✅ **npm**: Validates npm availability
- ✅ **Git**: Ensures Git is installed for Vercel authentication
- ✅ **Rust Toolchain**: Validates Rust installation and toolchain
- ✅ **Cross-compilation**: Checks for cargo-zigbuild or cross
- ✅ **Docker**: Validates Docker installation (if using Docker build)
- ✅ **Vercel CLI**: Ensures Vercel CLI is installed and authenticated

### Build Process
1. **Dependency Installation**: Runs `npm install` to install Node.js dependencies
2. **Rust CLI Compilation**: Builds the Rust binary using the best available method:
   - Prefers local Rust toolchain with cargo-zigbuild
   - Falls back to Docker build if local Rust unavailable
3. **Next.js Build**: Compiles the Next.js application for production
4. **Binary Validation**: Ensures the compiled binary is executable and properly placed

### Deployment Process
1. **Vercel Authentication**: Validates Vercel CLI authentication
2. **Production Deployment**: Deploys to Vercel with `--prod` flag
3. **Deployment Verification**: Confirms successful deployment

### Usage

**Direct Script Execution:**
```bash
# Make the script executable (first time only)
chmod +x scripts/build-and-deploy.sh

# Run complete build and deployment
./scripts/build-and-deploy.sh

# Or run with verbose output
./scripts/build-and-deploy.sh --verbose
```

**Package Manager Scripts (Alternative):**
```bash
# Using npm
npm run build:deploy
npm run build:deploy:verbose

# Using yarn
yarn run build:deploy
yarn run build:deploy:verbose
```

### Platform Support
- **macOS (OSX)**: Primary target with Homebrew package manager
- **Linux**: Ubuntu/Debian support with apt package manager
- **Auto-detection**: Automatically detects OS and adjusts commands accordingly

## Project Structure

```
├── pages/
│   ├── index.js          # Main React component with ping/message UI
│   └── _app.js           # Next.js app wrapper
├── api/
│   ├── proxy.js          # Vercel function that spawns Rust binary
│   └── bin/              # Compiled Rust CLI binary (generated)
├── rust-cli/
│   ├── Cargo.toml        # Rust dependencies
│   └── src/main.rs       # Rust CLI with ping/pong logic
├── scripts/
│   ├── build-cli.sh      # Local build script
│   ├── build-cli-docker.sh # Docker build script
│   └── build-and-deploy.sh # Complete build & deploy automation
├── docker/
│   └── cli.Dockerfile    # Docker build for Rust binary
├── package.json          # Node.js dependencies and scripts
├── vercel.json           # Vercel configuration
└── README.md             # This file
```

## Troubleshooting

### Common Issues

**Missing Cross-Compilation Tools**
```bash
# Install cargo-zigbuild (recommended)
cargo install cargo-zigbuild
brew install zig  # macOS
sudo apt install zig  # Linux
```

**Docker Not Running**
```bash
# Start Docker service
brew services start docker  # macOS
sudo systemctl start docker  # Linux
```

**Vercel Authentication Issues**
```bash
# Login to Vercel
vercel login

# Check authentication status
vercel whoami
```

**Node.js Version Mismatch**
```bash
# Check current version
node --version

# Install Node.js 22.x if needed
brew install node@22  # macOS
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs  # Linux
```

**Binary Not Executable**
```bash
# Fix permissions
chmod +x api/bin/cli
```

### Script Debugging

**Enable Verbose Output**
```bash
./scripts/build-and-deploy.sh --verbose
# or
npm run build:deploy:verbose
# or
yarn run build:deploy:verbose
```

**Check Individual Components**
```bash
# Test Rust CLI build only
npm run build:cli
# or
yarn run build:cli

# Test Docker build only
npm run build:cli:docker
# or
yarn run build:cli:docker

# Test Next.js build only
npm run build
# or
yarn build
```

## Customization

- **Frontend**: Modify `pages/index.js` for UI changes
- **Rust Logic**: Update `rust-cli/src/main.rs` for custom processing
- **API**: Modify `api/proxy.js` for different binary interaction patterns
- **Styling**: Update `styles/globals.css` for custom Tailwind styles