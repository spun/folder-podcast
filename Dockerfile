# ===== Build stage =====
FROM docker.io/denoland/deno:2.6.4@sha256:dc1f650df3a304a516f500ca001423aade30f430f5d053c5b235d50741eddc85 AS builder
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
