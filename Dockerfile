# ===== Build stage =====
FROM docker.io/denoland/deno:2.7.14@sha256:564e989f4a93371e70fd8720e5dbe3e027fd4a0daad71a2b008008596ffa6492 AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:8f960b7fc6a5d6e28bb07f982655925d6206678bd9a6cde2ad00ddb5e2077d78
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
