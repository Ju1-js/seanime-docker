import { copyFile, mkdir, mkdtemp, rm } from "node:fs/promises";
import { resolve } from "node:path";
import { $ } from "bun";

const target = Bun.argv[2] ?? "slim";
if (!["slim", "hwaccel", "cuda"].includes(target)) {
  console.error("Usage: bun run test:image [slim|hwaccel|cuda]");
  process.exit(1);
}

const bash =
  process.platform === "win32"
    ? resolve((await $`git --exec-path`.text()).trim(), "../../../bin/bash.exe")
    : "bash";
const release = (await Bun.file(".version").text()).trim();
const image = `seanime:local-${target}`;
await mkdir("tmp", { recursive: true });
const context = await mkdtemp("tmp/image-test-");
const contextPath = resolve(context);
const imageIdFile = resolve(contextPath, "image-id");

try {
  await $`${bash} scripts/prepare.sh ${release} ${context}/src`;
  await mkdir(`${context}/scripts`);
  for (const file of ["Dockerfile", ".dockerignore", "scripts/patch-deps.go"]) {
    await copyFile(file, `${context}/${file}`);
  }
  // Linux executes this file directly, so the shebang must end in LF.
  const healthcheck = await Bun.file("scripts/healthcheck.sh").text();
  await Bun.write(`${context}/scripts/healthcheck.sh`, healthcheck.replaceAll("\r\n", "\n"));
  await $`docker buildx build --target ${target} --load --iidfile ${imageIdFile} -t ${image} ${contextPath}`;
  await $`bun run smoke:image ${(await Bun.file(imageIdFile).text()).trim()}`;
} finally {
  await rm(contextPath, { recursive: true, force: true });
}
