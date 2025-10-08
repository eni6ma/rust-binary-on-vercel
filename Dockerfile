# Minimal Docker build for Vercel Rust CLI
# Builds the Rust binary and prepares it for deployment

FROM ghcr.io/messense/cargo-zigbuild:latest AS builder

WORKDIR /app

# Copy only Cargo.toml first for dependency caching
COPY rust-cli/Cargo.toml ./rust-cli/

# Create a dummy main.rs to cache dependencies
RUN mkdir -p rust-cli/src && \
    echo "fn main() {}" > rust-cli/src/main.rs && \
    cd rust-cli && \
    cargo zigbuild --release --target x86_64-unknown-linux-musl || true

# Copy the actual source code
COPY rust-cli/src/ ./rust-cli/src/

# Build the actual binary
WORKDIR /app/rust-cli
RUN cargo zigbuild --release --target x86_64-unknown-linux-musl

# Verify the binary
RUN file target/x86_64-unknown-linux-musl/release/cli && \
    ls -la target/x86_64-unknown-linux-musl/release/cli

# Export stage - just the binary
FROM scratch AS export
COPY --from=builder /app/rust-cli/target/x86_64-unknown-linux-musl/release/cli /cli