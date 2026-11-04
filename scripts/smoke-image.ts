import { $ } from "bun";

const image = Bun.argv[2] ?? process.env.SEANIME_SMOKE_IMAGE;
if (!image?.trim()) {
  console.error("Specify a locally built image: bun run smoke:image seanime:local");
  process.exit(1);
}
const inspection = await $`docker image inspect ${image}`.quiet().nothrow();
if (inspection.exitCode !== 0) {
  console.error(inspection.stderr.toString().trim());
  console.error("Build and load the image before running the smoke test.");
  process.exit(1);
}
const container = `seanime-smoke-${crypto.randomUUID()}`;
const stateFormat = "{{.State.Status}}/{{if .State.Health}}{{.State.Health.Status}}{{end}}";

async function smokeTest() {
  console.log(`Smoke-testing ${image}`);
  await $`docker run --pull=never -d --name ${container} ${image}`.quiet();
  const stopAt = Date.now() + 90_000;
  while (Date.now() < stopAt) {
    const status = (await $`docker inspect --format ${stateFormat} ${container}`.text()).trim();
    if (status === "running/healthy") {
      await $`docker exec ${container} ffmpeg -version`.quiet();
      await $`docker exec ${container} ffprobe -version`.quiet();
      console.log("Seanime is healthy and FFmpeg and FFprobe run.");
      return;
    }
    if (status !== "running/starting") {
      throw new Error(`Unexpected container state: ${status}`);
    }
    await Bun.sleep(1_000);
  }
  throw new Error("Seanime did not become healthy within 90 seconds.");
}

try {
  await smokeTest();
} catch (error) {
  await $`docker logs --tail 80 ${container}`.nothrow();
  throw error;
} finally {
  await $`docker rm -fv ${container}`.quiet().nothrow();
}
