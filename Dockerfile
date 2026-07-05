# ===== Build stage =====
FROM docker.io/denoland/deno:2.9.1@sha256:c40ad61ed0b40cca8fda05a2bbf44f8e02485bebec8ee4820bdb4b6fff42599d AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:d3cda6e91129130d7229a1806b6a73d292ef245ab032da7851907798024cefba
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
