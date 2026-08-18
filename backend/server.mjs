import http from "node:http";
import { createBriefing, isAuthorized, parseRequestURL } from "./lib/briefing.mjs";

const port = Number(process.env.PORT || 8787);
const server = http.createServer(async (request, response) => {
  response.setHeader("Content-Type", "application/json; charset=utf-8");
  response.setHeader("Access-Control-Allow-Origin", process.env.ALLOWED_ORIGIN || "*");
  if (request.method === "GET" && request.url === "/health") {
    response.writeHead(200).end(JSON.stringify({ status: "ok" }));
    return;
  }
  if (request.method !== "GET" || !request.url.startsWith("/v1/briefing")) {
    response.writeHead(404).end(JSON.stringify({ error: "not_found" }));
    return;
  }
  if (!isAuthorized(request.headers.authorization, process.env.CATCHUP_ACCESS_TOKEN)) {
    response.writeHead(401).end(JSON.stringify({ error: "unauthorized" }));
    return;
  }
  try {
    const { topics, count } = parseRequestURL(request.url);
    const briefing = await createBriefing({ topics, count, apiKey: process.env.PERPLEXITY_API_KEY, model: process.env.PERPLEXITY_MODEL || "sonar" });
    response.writeHead(200).end(JSON.stringify(briefing));
  } catch (error) {
    response.writeHead(error.statusCode || 500).end(JSON.stringify({ error: error.message }));
  }
});

server.listen(port, () => console.log(`Catch Up backend listening on http://localhost:${port}`));

