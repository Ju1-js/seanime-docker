import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { resolve } from "node:path";
import { $ } from "bun";

const bash =
  process.platform === "win32"
    ? resolve((await $`git --exec-path`.text()).trim(), "../../../bin/bash.exe")
    : "bash";
const release = (await Bun.file(".version").text()).trim();
await mkdir("tmp", { recursive: true });
const context = await mkdtemp("tmp/patch-review-");
const contextPath = resolve(context);

try {
  await $`${bash} scripts/prepare.sh ${release} ${context}/src`;
  await $`${bash} scripts/review-patches.sh ${context}/src`;
} finally {
  await rm(contextPath, { recursive: true, force: true });
}
