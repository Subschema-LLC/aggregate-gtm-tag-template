#!/usr/bin/env node

/**
 * Release helper utility for Aggregate GTM template.
 * Follows the convention: v[YEAR].[MN].[INDEX]
 * where INDEX is the 2-digit release number for that month (not the day).
 */

import { execSync } from "node:child_process";

export function getNextVersion(date = new Date(), customTags = null) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");

  let tags = customTags;
  if (!tags) {
    try {
      const output = execSync("git tag -l", { encoding: "utf8" });
      tags = output.split("\n").map(t => t.trim()).filter(Boolean);
    } catch {
      tags = [];
    }
  }

  const regex = new RegExp("^v" + year + "\\." + month + "\\.([0-9]+)$");
  const existingIndices = tags
    .map(t => regex.exec(t))
    .filter(Boolean)
    .map(m => parseInt(m[1], 10));

  const nextIndex = existingIndices.length > 0 ? Math.max(...existingIndices) + 1 : 1;
  const indexStr = String(nextIndex).padStart(2, "0");
  return "v" + year + "." + month + "." + indexStr;
}

if (process.argv[1] && process.argv[1].endsWith("release.mjs")) {
  const arg = process.argv[2];
  const nextVer = getNextVersion();

  if (arg === "--next") {
    console.log(nextVer);
    process.exit(0);
  }

  console.log("Next release version: " + nextVer);
  console.log("Convention: v[YEAR].[MN].[INDEX] (where INDEX is the release counter for this month)");
}
