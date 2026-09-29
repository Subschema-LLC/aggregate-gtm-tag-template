import assert from "node:assert/strict";
import test from "node:test";
import { getNextVersion, validateTag } from "../scripts/release.mjs";

test("getNextVersion defaults to 01 when no tags exist for the month", () => {
  const ver = getNextVersion(new Date("2026-10-15T12:00:00Z"), []);
  assert.equal(ver, "v2026.10.01");
});

test("getNextVersion increments index when tags already exist for the month", () => {
  const ver = getNextVersion(new Date("2026-09-29T12:00:00Z"), ["v2026.09.01", "v2026.09.02"]);
  assert.equal(ver, "v2026.09.03");
});

test("getNextVersion ignores tags from other months or years", () => {
  const ver = getNextVersion(new Date("2026-10-01T12:00:00Z"), ["v2026.09.01", "v2026.09.02", "v2025.10.05"]);
  assert.equal(ver, "v2026.10.01");
});

test("getNextVersion formats two-digit padded index correctly", () => {
  const ver = getNextVersion(new Date("2026-09-01T00:00:00Z"), ["v2026.09.09"]);
  assert.equal(ver, "v2026.09.10");
});

test("validateTag validates vYYYY.MM.NN format", () => {
  assert.ok(validateTag("v2026.09.01"));
  assert.ok(validateTag("v2026.12.99"));
  assert.ok(!validateTag("2026.09.01"));
  assert.ok(!validateTag("v2026.9.1"));
  assert.ok(!validateTag("v2026.09.1"));
  assert.ok(!validateTag("v2026.09.001"));
  assert.ok(!validateTag("invalid"));
});
