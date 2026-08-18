# Catch Up news backend

This zero-dependency Node service protects the Perplexity key, generates a finite cited briefing, validates source URLs against citations returned by Perplexity, and returns the app's JSON contract.

## Local test

```sh
node --test
```

## Local run

Set `PERPLEXITY_API_KEY` and a long random `CATCHUP_ACCESS_TOKEN` in your environment, then:

```sh
node server.mjs
```

Call `http://localhost:8787/v1/briefing?topics=World,Energy,Technology&count=3` with `Authorization: Bearer YOUR_ACCESS_TOKEN`.

## Vercel deployment

1. Create a Vercel project from the `backend` folder.
2. Add `PERPLEXITY_API_KEY` and a long random `CATCHUP_ACCESS_TOKEN` as encrypted environment variables.
3. Optionally set `PERPLEXITY_MODEL` (default: `sonar`) and `ALLOWED_ORIGIN`.
4. Deploy, then enter the resulting HTTPS origin and the same access token in Catch Up settings—without a trailing `/v1/briefing`.

The in-memory cache reduces repeat provider calls for the same day, topics, and story count. A production deployment may replace it with a shared durable cache if it scales beyond one server instance.

