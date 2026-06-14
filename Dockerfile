# ===== Build stage =====
FROM docker.io/denoland/deno:2.8.3@sha256:438618d8c0678c3154fc77ad6edad61f38cbc42803a181e7908d3e2c9e645022 AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:e1fd250ce83d94603e9887ec991156a6c26905a6b0001039b7a43699018c0733
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
