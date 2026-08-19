import { createHash } from "node:crypto";
import { readFile, stat, writeFile } from "node:fs/promises";
import { basename, resolve } from "node:path";

function argumentsFrom(commandLine) {
  const values = {};
  for (let index = 0; index < commandLine.length; index += 2) {
    const key = commandLine[index];
    const value = commandLine[index + 1];
    if (!key?.startsWith("--") || value == null) throw new Error(`Invalid argument near ${key || "end of command"}`);
    values[key.slice(2)] = value;
  }
  return values;
}

function required(values, key) {
  if (!values[key]) throw new Error(`Missing required --${key}`);
  return values[key];
}

const values = argumentsFrom(process.argv.slice(2));
const ipaPath = resolve(required(values, "ipa"));
const owner = required(values, "owner");
const repository = values.repo || "catch-up";
const bundleIdentifier = values["bundle-id"] || "com.yourname.CatchUpFree";
const developerName = required(values, "developer");
const version = values.version || "1.0.0";
const buildVersion = values.build || "1";
const output = resolve(values.output || "source.json");
const releaseTag = values.tag || `v${version}`;
const releaseDate = values.date || new Date().toISOString().slice(0, 10);
const ipaName = values["ipa-name"] || basename(ipaPath);

const ipaData = await readFile(ipaPath);
const ipaDetails = await stat(ipaPath);
const sha256 = createHash("sha256").update(ipaData).digest("hex");
const repositoryURL = `https://github.com/${owner}/${repository}`;
const releaseRoot = `${repositoryURL}/releases/download/${releaseTag}`;
const releaseURL = `${releaseRoot}/${ipaName}`;
const iconURL = `${releaseRoot}/CatchUp-AppIcon-1024.png`;

const source = {
  name: "Catch Up",
  subtitle: "A finite morning news habit",
  description: "Catch Up turns your morning alarm into a short, focused news briefing with progress and streaks.",
  iconURL,
  website: repositoryURL,
  tintColor: "#111111",
  featuredApps: [bundleIdentifier],
  apps: [{
    name: "Catch Up",
    bundleIdentifier,
    developerName,
    subtitle: "Wake up informed",
    localizedDescription: "Set a morning alarm, read a finite briefing, and build a daily news habit. This free-sideload edition omits Screen Time shielding because that feature requires an Apple-managed entitlement.",
    iconURL,
    tintColor: "#111111",
    category: "utilities",
    versions: [{
      version,
      buildVersion,
      date: releaseDate,
      localizedDescription: "Initial SideStore release.",
      downloadURL: releaseURL,
      size: ipaDetails.size,
      sha256,
      minOSVersion: "26.0"
    }],
    appPermissions: {
      entitlements: [],
      privacy: {
        NSAlarmKitUsageDescription: "Catch Up schedules your morning alarm and opens your daily news briefing."
      }
    }
  }],
  news: []
};

await writeFile(output, `${JSON.stringify(source, null, 2)}\n`, "utf8");
console.log(`Created ${output}`);
console.log(`IPA: ${ipaDetails.size} bytes`);
console.log(`SHA-256: ${sha256}`);
console.log(`SideStore source URL after release publishing: ${releaseRoot}/sidestore-source.json`);
