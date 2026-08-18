import { createHash } from "node:crypto";
import { timingSafeEqual } from "node:crypto";

export const ALLOWED_TOPICS = new Set(["World", "Energy", "Technology", "Business", "Science"]);
const memoryCache = new Map();

export function isAuthorized(headerValue, expectedToken) {
  if (!expectedToken) return true;
  const supplied = String(headerValue || "").replace(/^Bearer\s+/i, "");
  const expected = Buffer.from(expectedToken);
  const received = Buffer.from(supplied);
  return expected.length === received.length && timingSafeEqual(expected, received);
}

export function parseRequestURL(rawURL, base = "http://localhost") {
  const url = new URL(rawURL, base);
  const requestedTopics = (url.searchParams.get("topics") || "World,Energy,Technology")
    .split(",")
    .map(value => value.trim())
    .filter(value => ALLOWED_TOPICS.has(value));
  const topics = [...new Set(requestedTopics)].slice(0, 5);
  const parsedCount = Number.parseInt(url.searchParams.get("count") || "3", 10);
  const count = Math.min(Math.max(Number.isFinite(parsedCount) ? parsedCount : 3, 3), 7);
  return { topics: topics.length ? topics : ["World"], count };
}

function responseSchema(count) {
  return {
    type: "object",
    additionalProperties: false,
    properties: {
      stories: {
        type: "array",
        minItems: count,
        maxItems: count,
        items: {
          type: "object",
          additionalProperties: false,
          properties: {
            section: { type: "string" },
            headline: { type: "string" },
            summary: { type: "string" },
            whyItMatters: { type: "string" },
            sourceName: { type: "string" },
            sourceURL: { type: "string" },
            publishedAt: { type: "string" },
            readTimeMinutes: { type: "integer" }
          },
          required: ["section", "headline", "summary", "whyItMatters", "sourceName", "sourceURL", "publishedAt", "readTimeMinutes"]
        }
      }
    },
    required: ["stories"]
  };
}

function buildPrompt(topics, count) {
  return [
    `Create a concise morning briefing of exactly ${count} distinct, consequential news stories.`,
    `Cover these interests fairly: ${topics.join(", ")}.`,
    "Prioritize developments from the last 24 hours, then use the last 72 hours only when needed for topic coverage.",
    "Use neutral language. Distinguish confirmed facts from uncertainty. Avoid sensationalism, opinion pieces, duplicate events, and celebrity news.",
    "Each summary must be 45-80 words and self-contained. Each whyItMatters must be 20-40 words.",
    "Use a real primary or reputable reporting source URL discovered during search for each story.",
    "publishedAt must be ISO 8601. readTimeMinutes must be 1 or 2.",
    "Return only the requested JSON object."
  ].join("\n");
}

function safeURL(value) {
  try {
    const url = new URL(value);
    return url.protocol === "https:" ? url : null;
  } catch {
    return null;
  }
}

function stableID(sourceURL, headline) {
  return createHash("sha256").update(`${sourceURL}|${headline}`).digest("hex").slice(0, 24);
}

export function normalizeStories(payload, permittedURLs, count, now = new Date()) {
  if (!payload || !Array.isArray(payload.stories)) throw new Error("Provider returned no stories");
  const citations = [...permittedURLs].map(safeURL).filter(Boolean);
  if (!citations.length) throw new Error("Provider returned no verifiable citations");

  const seen = new Set();
  const stories = [];
  for (const [index, item] of payload.stories.entries()) {
    if (!item || typeof item.headline !== "string" || typeof item.summary !== "string") continue;
    let source = safeURL(item.sourceURL);
    const sourceWasVerified = Boolean(source && permittedURLs.has(source.href));
    if (!sourceWasVerified) source = citations[index % citations.length];
    const dedupeKey = source.href.toLowerCase();
    if (seen.has(dedupeKey)) continue;
    seen.add(dedupeKey);
    const published = new Date(item.publishedAt);
    stories.push({
      id: stableID(source.href, item.headline.trim()),
      section: ALLOWED_TOPICS.has(item.section) ? item.section.toUpperCase() : "WORLD",
      headline: item.headline.trim().slice(0, 180),
      summary: item.summary.trim().slice(0, 700),
      whyItMatters: String(item.whyItMatters || "This development may affect decisions beyond today's headlines.").trim().slice(0, 360),
      sourceName: String(sourceWasVerified ? (item.sourceName || source.hostname) : source.hostname).trim().slice(0, 80),
      sourceURL: source.href,
      publishedAt: Number.isNaN(published.valueOf()) ? now.toISOString() : published.toISOString(),
      readTimeMinutes: Math.min(Math.max(Number(item.readTimeMinutes) || 1, 1), 3)
    });
    if (stories.length === count) break;
  }
  if (stories.length < count) throw new Error("Provider returned too few distinct cited stories");
  return stories;
}

export async function createBriefing({ topics, count, apiKey, model = "sonar", fetchImpl = fetch, now = new Date() }) {
  if (!apiKey) throw Object.assign(new Error("PERPLEXITY_API_KEY is not configured"), { statusCode: 503 });
  const day = now.toISOString().slice(0, 10);
  const cacheKey = `${day}|${topics.slice().sort().join(",")}|${count}`;
  const cached = memoryCache.get(cacheKey);
  if (cached && now.valueOf() - cached.createdAt < 30 * 60 * 1000) return cached.value;

  const response = await fetchImpl("https://api.perplexity.ai/v1/sonar", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model,
      messages: [
        { role: "system", content: "You are the careful editor of a finite daily news briefing. Accuracy and source fidelity are more important than novelty." },
        { role: "user", content: buildPrompt(topics, count) }
      ],
      search_recency_filter: "week",
      response_format: {
        type: "json_schema",
        json_schema: { name: "daily_briefing", schema: responseSchema(count) }
      }
    })
  });
  if (!response.ok) {
    const detail = await response.text();
    throw Object.assign(new Error(`News provider failed (${response.status}): ${detail.slice(0, 200)}`), { statusCode: 502 });
  }
  const provider = await response.json();
  const content = provider?.choices?.[0]?.message?.content;
  if (typeof content !== "string") throw Object.assign(new Error("News provider returned an invalid response"), { statusCode: 502 });
  const payload = JSON.parse(content);
  const permittedURLs = new Set([
    ...(Array.isArray(provider.citations) ? provider.citations : []),
    ...(Array.isArray(provider.search_results) ? provider.search_results.map(result => result?.url).filter(Boolean) : [])
  ].map(value => safeURL(value)?.href).filter(Boolean));
  const value = { generatedAt: now.toISOString(), stories: normalizeStories(payload, permittedURLs, count, now) };
  memoryCache.set(cacheKey, { createdAt: now.valueOf(), value });
  return value;
}

