Create and serve an XML podcast feed from the media files in a folder.

## How it works

When you run the image, a Deno app will scan the media files inside the given folder and use their metadata to generate a podcast XML feed, with entries pointing to each file.

## Why

If your podcast app fetches feeds directly (instead of relying on a remote server), this can be used to share local media files in a format the app can understand.

## How to run

**NOTE:** The generated XML includes entries with the full media URL. To generate these URLs, the app needs to know the public `IP:PORT` that clients will use to access the feed. This is why our run commands require the `HOST_IP` and `HOST_PORT` `environment variables.

### Option 1: Run prebuilt image

You can pull and run the prebuilt image directly.

Go to the folder with your media files and run something like this:

```bash
docker run --rm --init \
-p 9000:8080 \
-v "$(pwd):/app/files:Z" \
-e HOST_IP=$(hostname -I | awk '{print $1}') \
-e HOST_PORT=9000 \
ghcr.io/spun/folder-podcast:latest
```

### Option 2: Build and run locally

Build the image:

```bash
docker build -t folder-podcast-app:1.0 .
```

Run the container from the folder with your media files:

```bash
docker run --rm --init \
-p 9000:8080 \
-v "$(pwd):/app/files:Z" \
-e HOST_IP=$(hostname -I | awk '{print $1}') \
-e HOST_PORT=9000 \
localhost/folder-podcast-app:1.0
```
