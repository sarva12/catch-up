import { createBriefing, isAuthorized, parseRequestURL } from "../../lib/briefing.mjs";

export default async function handler(request, response) {
  const origin = process.env.ALLOWED_ORIGIN || "*";
  response.setHeader("Access-Control-Allow-Origin", origin);
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  if (request.method !== "GET") return response.status(405).json({ error: "method_not_allowed" });
  if (!isAuthorized(request.headers.authorization, process.env.CATCHUP_ACCESS_TOKEN)) {
    return response.status(401).json({ error: "unauthorized" });
  }
  try {
    const { topics, count } = parseRequestURL(request.url);
    const briefing = await createBriefing({
      topics,
      count,
      apiKey: process.env.PERPLEXITY_API_KEY,
      model: process.env.PERPLEXITY_MODEL || "sonar"
    });
    return response.status(200).json(briefing);
  } catch (error) {
    const status = error.statusCode || 500;
    return response.status(status).json({ error: status === 500 ? "internal_error" : error.message });
  }
}

