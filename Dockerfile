# ===== Build stage =====
FROM docker.io/denoland/deno:2.6.8@sha256:acc18ab12bdb8505043a6c14553ae0a1b8211d6febc29db2aba8989ddbac8bad AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:1460b2049b1d605cba0b45c73d5e3971dcce300cfd3b95acfe22b2f34e1f5d88
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
