import { Application } from "@oak/oak/application";
import { Router } from "@oak/oak/router";
import { stringify, type xml_document } from "@libs/xml";
import { debounce } from "jsr:@std/async/debounce";
import { extname } from "jsr:@std/path";
import { contentType, typeByExtension } from "@std/media-types";

/*
// If we want better guid values, we could calculate the SHA256 hash for each file.
import { crypto } from "jsr:@std/crypto";
import { encodeHex } from "jsr:@std/encoding/hex";

async function getSHA256(entry: Deno.DirEntry) {
  if (entry.isFile) {
    const file = await Deno.open(`./files/${entry.name}`, { read: true });
    const readableStream = file.readable;

    const fileHashBuffer = await crypto.subtle.digest(
      "SHA-256",
      readableStream,
    );

    const fileHash = encodeHex(fileHashBuffer);
    console.log({ name: entry.name, hash: fileHash });
  }
}
*/

// #region Get configuration values from env variables
// Since our xml would need to include full urls to the media files, we need
// to know the public address the host will use to serve the feed.
// We use env variables to get the info from the host.
const hostIp = Deno.env.get("HOST_IP");
const hostPort = Deno.env.get("HOST_PORT");
if (!hostIp || !hostPort) {
  console.error(
    "Environment variables HOST_IP and HOST_PORT are required. Exiting...",
  );
  Deno.exit(1); // Exit with a non-zero code.
}
const hostAddress = `${hostIp}:${hostPort}`;
// #endregion

// #region Read folder content
// Check if the files folder we are going to use to generate the feed exists.
try {
  const stat = await Deno.stat("./files");
  if (!stat.isDirectory) {
    console.log('Path "./files" exists, but it\'s not a folder.');
    Deno.exit(1); // Exit with a non-zero code
  }
} catch (err) {
  if (!(err instanceof Deno.errors.NotFound)) {
    throw err;
  }
  console.log('Folder "./files" does not exist');
  Deno.exit(1); // Exit with a non-zero code.
}

// Get the list of files in the "files" folder.
// Store audio files.
const audioFiles: {
  guid: string;
  filename: string;
  size: number;
  modified: Date;
}[] = [];
// Check if the folder has an artwork file.
let artworkFilename: string | null = null;

async function updateInfoFromFolder() {
  console.log("Updating podcast info...");
  audioFiles.length = 0;
  artworkFilename = null;
  for await (const entry of Deno.readDir("./files")) {
    if (entry.isFile) {
      // Add only audio files.
      const filePath = `./files/${entry.name}`;
      const extension = extname(filePath);
      const fileType = typeByExtension(extension);
      if (fileType?.startsWith("audio/")) {
        const info = await Deno.stat(filePath);
        audioFiles.push({
          guid: encodeURI(entry.name),
          filename: entry.name,
          size: info.size,
          modified: info.mtime ?? new Date(), // use current date if null.
        });
      }
      // Check for an image file we should use as the podcast artwork.
      if (artworkFilename == null && fileType?.startsWith("image/")) {
        artworkFilename = entry.name;
      }
    }
  }
  // Sort by modification date, newest first.
  audioFiles.sort((a, b) => b.modified.getTime() - a.modified.getTime());
  const hasArtwork = artworkFilename != null;
  console.log(
    `Update completed: ${audioFiles.length} audio files | hasArtwork is ${hasArtwork}`,
  );
}
// Set initial values.
await updateInfoFromFolder();

// Watch the filesystem for changes.
(async () => {
  // A filesystem watcher could dispatch multiple events for the same change.
  // Use debounce to avoid reacting multiple to one change.
  const update = debounce((event: Deno.FsEvent) => {
    console.log("[%s] %s", event.kind, event.paths[0]);
    updateInfoFromFolder();
  }, 200);

  const watcher = Deno.watchFs("./files");
  for await (const event of watcher) {
    update(event);
  }
})();
// #endregion

// #region Router creation
// Create a router to handle two routes:
// - "/" for the xml feed
// - "audios/" for the static audio files
const router = new Router();
router
  .get("/", (context) => {
    console.info(`FEED: Request for xml feed`);
    // Generate feed xml
    const feed = stringify(
      {
        "@version": "1.0",
        "@encoding": "UTF-8",
        rss: {
          "@version": "2.0",
          "@xmlns:itunes": "http://www.itunes.com/dtds/podcast-1.0.dtd",
          "@xmlns:content": "http://purl.org/rss/1.0/modules/content/",
          channel: {
            title: "Podcast from folder",
            description: "A podcast generated with files from a folder",
            image: {
              url: `http://${hostAddress}/static/artwork`,
            },
            "itunes:image": {
              "@href": `http://${hostAddress}/static/artwork`,
            },
            item: audioFiles.map((audio) => ({
              title: audio.filename,
              guid: audio.guid,
              pubDate: audio.modified.toUTCString(),
              enclosure: {
                "@length": audio.size,
                "@type": "audio/mpeg",
                "@url": `http://${hostAddress}/audios/${audio.guid}`,
              },
            })),
          },
        },
      } satisfies Partial<xml_document>,
    );

    context.response.type = "application/xml";
    context.response.body = feed;
  })
  .get("/audios/:audioGuid", async (context) => {
    // Serve static files
    // We use encode here because it seems that params are automatically decoded our
    // original and we don't want that.
    // We could use the decoded value and check it against the final filename but it
    // doesn't feel right. Our param represents the guid, and we should check it against
    // the stored guid even if right know one is derived from the other.
    // If we decide to change how we generate guid values (hash?) we need to remove this.
    const audioFileParam = encodeURI(context.params.audioGuid);
    console.info(`AUDIO: Request for "${audioFileParam}"`);
    if (audioFileParam) {
      const audioItem = audioFiles.find((item) => item.guid === audioFileParam);
      if (audioItem) {
        const filename = audioItem.filename;
        const fileInfo = await Deno.stat(`./files/${filename}`);
        context.response.headers.set("Content-Length", `${fileInfo.size}`);
        await context.send({ root: `./files`, path: filename });
      } else {
        // Avoid sending any file inside the files folder.
        // We only return files that we previously used to generate the xml.
        console.warn(`- "${audioFileParam}" is not a valid media file`);
      }
    }
    // A response without .body should send a 404 Not found.
  }).get("/static/artwork", async (context) => {
    // Serve static artwork file.
    const artworkPath = artworkFilename != null
      ? `./files/${artworkFilename}`
      : `./static/artwork-default.png`;
    console.info(`ARTWORK: New request "${artworkPath}"`);
    // Get content-type.
    const extension = extname(artworkPath);
    const type = contentType(extension);
    if (type) {
      context.response.headers.set("Content-Type", type);
    }
    // Get content-length.
    const fileInfo = await Deno.stat(artworkPath);
    context.response.headers.set("Content-Length", `${fileInfo.size}`);
    // Send file
    await context.send({ root: `./`, path: artworkPath });
  });
// #endregion

// #region Start server
const app = new Application();
app.use(router.routes());
app.use(router.allowedMethods());

// This is an event fired once the server is open, before it starts processing requests.
app.addEventListener("listen", ({ hostname, port, secure }) => {
  const internalAddress = `${secure ? "https://" : "http://"}${
    hostname ?? "localhost"
  }:${port}`;
  console.log(`Listening on: ${internalAddress} -> http://${hostAddress}`);
});
await app.listen({ hostname: "0.0.0.0", port: 8080 });
// #endregion
