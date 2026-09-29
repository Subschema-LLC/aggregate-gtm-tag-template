import assert from "node:assert/strict";
import test from "node:test";
import { getNextVersion } from "../scripts/release.mjs";

test("getNextVersion generates v[YEAR].[MN].[INDEX] format", () => {
  const ver = getNextVersion(new Date("2026-09-29T12:00:00Z"));
  assert.match(ver, /^v2026\.09\.[0-9]{2}$/);
});

test("getNextVersion correctly pads month and index", () => {
  const jan = getNextVersion(new Date("2027-01-05T00:00:00Z"));
  assert.equal(jan.slice(0, 8), "v2027.01");
});
