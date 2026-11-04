import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { $ } from "bun";

const composeFiles = Array.from(new Bun.Glob("examples/**/docker-compose.yml").scanSync()).sort();
if (composeFiles.length === 0) {
  throw new Error("No Compose examples found. Run from the repository root.");
}

for (const file of composeFiles) {
  const fixture = join(dirname(file), ".env.example");
  // An explicit env-file disables automatic loading of a contributor's .env.
  const envArgs = existsSync(fixture) ? ["--env-file", fixture] : [];
  console.log(`Validating ${file}`);
  await $`COMPOSE_DISABLE_ENV_FILE=1 docker compose ${envArgs} -f ${file} config --quiet`;
}
