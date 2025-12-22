# ===== Build stage =====
FROM docker.io/denoland/deno:2.6.3@sha256:075c8d994cf1e44f10d98ea86f6693037e9c66eb83e9b5fa6a534147372de3fb AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:2575808fe33e2a728348040ef2fd6757b0200a73ca8daebd0c258e2601e76c6d
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
