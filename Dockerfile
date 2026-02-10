# ===== Build stage =====
FROM docker.io/denoland/deno:2.6.7@sha256:293e593b7c43c33f6cc693142da3c549f40bd527aabcdd2dd48e5222e071b04d AS builder
# Set working directory
WORKDIR /app
# Copy source files
COPY . .
# Compile to standalone executable
RUN deno task build

# ===== Production stage =====
FROM gcr.io/distroless/cc:nonroot@sha256:5c94e1d2e831f0fadfe4048427f6ff3a91481606da2841c5b26674220ac84d2d
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
