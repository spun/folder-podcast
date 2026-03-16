# ===== Build stage =====
FROM docker.io/denoland/deno:2.7.4@sha256:4212a880f06e8dec28184688cce3449cc6e75232480e527342906b7c7ffc7b8d AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:9c4fe2381c2e6d53c4cfdefeff6edbd2a67ec7713e2c3ca6653806cbdbf27a1e
# Set working directory
WORKDIR /app
# Copy the compiled binary
COPY --from=builder --chown=nonroot:nonroot --chmod=500 /app/folder-podcast-app .
# Copy the static files folder
COPY --chown=nonroot:nonroot --chmod=500 static/ static/
# Switch to nonroot user (optional with nonroot distroless)
USER nonroot
# Deno app port
EXPOSE 8080
# Run the app
CMD ["./folder-podcast-app"]
