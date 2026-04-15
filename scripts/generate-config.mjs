import { mkdir, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = dirname(fileURLToPath(import.meta.url));
const projectRoot = resolve(__dirname, "..");
const targetFile = resolve(projectRoot, "config.local.js");

const config = {
  supabaseUrl: process.env.SUPABASE_URL ?? "",
  supabaseAnonKey: process.env.SUPABASE_ANON_KEY ?? "",
};

const fileContents = `window.POLLY_WORD_CONFIG = Object.assign(
  {},
  window.POLLY_WORD_CONFIG || {},
  ${JSON.stringify(config, null, 2)}
);
`;

await mkdir(projectRoot, { recursive: true });
await writeFile(targetFile, fileContents, "utf8");

const mode = config.supabaseUrl && config.supabaseAnonKey ? "supabase" : "local";
console.log(`Generated config.local.js in ${mode} mode.`);
