#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
CLI_DIR="$ROOT_DIR/rust-cli"
OUT_DIR="$ROOT_DIR/api/bin"
TARGET_TRIPLE="x86_64-unknown-linux-musl"

mkdir -p "$OUT_DIR"

if ! command -v rustup >/dev/null 2>&1; then
	echo "rustup is required. Install from https://rustup.rs" >&2
	exit 1
fi

rustup target add "$TARGET_TRIPLE" >/dev/null 2>&1 || true

build_with_zig() {
	# Check for cargo-zigbuild in PATH or asdf Rust installation
	local zigbuild_cmd=""
	if command -v cargo-zigbuild >/dev/null 2>&1; then
		zigbuild_cmd="cargo-zigbuild"
	elif [[ -n "$(rustup show home 2>/dev/null)" ]] && [[ -f "$(rustup show home)/bin/cargo-zigbuild" ]]; then
		zigbuild_cmd="$(rustup show home)/bin/cargo-zigbuild"
	fi
	
	if [[ -n "$zigbuild_cmd" ]]; then
		(
			cd "$CLI_DIR"
			"$zigbuild_cmd" zigbuild --release --target "$TARGET_TRIPLE"
		)
		return 0
	fi
	return 1
}

build_with_cross() {
	if command -v cross >/dev/null 2>&1; then
		(
			cd "$CLI_DIR"
			cross build --release --target "$TARGET_TRIPLE"
		)
		return 0
	fi
	return 1
}

if build_with_zig || build_with_cross; then
	cp "$CLI_DIR/target/$TARGET_TRIPLE/release/cli" "$OUT_DIR/cli"
	chmod +x "$OUT_DIR/cli"
	echo "Built cli -> $OUT_DIR/cli"
	exit 0
fi

echo "Failed to produce $TARGET_TRIPLE binary." >&2
echo "Suggested setup:" >&2
echo "  1) cargo install cargo-zigbuild && brew install zig   # preferred on macOS" >&2
echo "  or" >&2
echo "  2) cargo install cross --git https://github.com/cross-rs/cross && have Docker running" >&2
exit 1