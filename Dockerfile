# ===== Build stage =====
FROM docker.io/denoland/deno:2.5.4@sha256:a5c9bbca7fe855a35a8656b7ce0ee7ff0084154d7c5cdc5005a89dc882a88b63 AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:39db8a6e7ab24face1bd5e935a1785ec335517c141141f3bdcbecff28efded42
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
