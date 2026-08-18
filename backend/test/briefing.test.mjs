import test from "node:test";
import assert from "node:assert/strict";
import { createBriefing, isAuthorized, normalizeStories, parseRequestURL } from "../lib/briefing.mjs";

test("access token comparison rejects absent and incorrect values", () => {
  assert.equal(isAuthorized("Bearer correct", "correct"), true);
  assert.equal(isAuthorized("Bearer wrong", "correct"), false);
  assert.equal(isAuthorized(undefined, "correct"), false);
  assert.equal(isAuthorized(undefined, undefined), true);
});

test("request parsing allowlists topics and bounds count", () => {
  const parsed = parseRequestURL("/v1/briefing?topics=Energy,Unknown,World&count=99");
  assert.deepEqual(parsed.topics, ["Energy", "World"]);
  assert.equal(parsed.count, 7);
});

test("normalization replaces an unverified source with a provider citation", () => {
  const permitted = new Set(["https://reuters.com/example"]);
  const result = normalizeStories({ stories: [{
    section: "Energy", headline: "Grid investment rises", summary: "A concise verified summary.",
    whyItMatters: "Infrastructure affects deployment.", sourceName: "Example", sourceURL: "https://fake.invalid/story",
    publishedAt: "2026-08-18T10:00:00Z", readTimeMinutes: 2
  }] }, permitted, 1);
  assert.equal(result[0].sourceURL, "https://reuters.com/example");
  assert.equal(result[0].sourceName, "reuters.com");
  assert.equal(result[0].section, "ENERGY");
  assert.equal(result[0].id.length, 24);
});

test("provider response becomes the iOS briefing contract", async () => {
  const providerBody = {
    choices: [{ message: { content: JSON.stringify({ stories: [
      { section: "World", headline: "A", summary: "Summary A", whyItMatters: "Why A", sourceName: "Reuters", sourceURL: "https://reuters.com/a", publishedAt: "2026-08-18T10:00:00Z", readTimeMinutes: 1 },
      { section: "Energy", headline: "B", summary: "Summary B", whyItMatters: "Why B", sourceName: "AP", sourceURL: "https://apnews.com/b", publishedAt: "2026-08-18T09:00:00Z", readTimeMinutes: 2 },
      { section: "Technology", headline: "C", summary: "Summary C", whyItMatters: "Why C", sourceName: "BBC", sourceURL: "https://bbc.com/c", publishedAt: "2026-08-18T08:00:00Z", readTimeMinutes: 2 }
    ] }) } }],
    citations: ["https://reuters.com/a", "https://apnews.com/b", "https://bbc.com/c"]
  };
  const fetchImpl = async () => new Response(JSON.stringify(providerBody), { status: 200, headers: { "Content-Type": "application/json" } });
  const result = await createBriefing({ topics: ["World", "Energy", "Technology"], count: 3, apiKey: "test", fetchImpl, now: new Date("2026-08-18T12:00:00Z") });
  assert.equal(result.stories.length, 3);
  assert.equal(result.stories[2].sourceName, "BBC");
});

