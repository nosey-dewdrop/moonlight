# Moonlight API Proxy

Cloudflare Worker that proxies Claude and FreeAstrologyAPI calls. Keeps API keys on the server, never on the device.

## Setup

```bash
cd backend
npm install -g wrangler
wrangler login

# Create KV namespace for rate limiting
wrangler kv:namespace create RATE_LIMIT
# Paste the id into wrangler.toml

# Set secrets
wrangler secret put CLAUDE_API_KEY
wrangler secret put ASTROLOGY_API_KEY
wrangler secret put APP_TOKEN

# Deploy
wrangler deploy
```

## Endpoints

- `POST /api/claude` — proxies to Claude API
- `POST /api/astrology/planets` — proxies to FreeAstrologyAPI
- `POST /api/astrology/houses` — proxies to FreeAstrologyAPI
- `POST /api/astrology/aspects` — proxies to FreeAstrologyAPI

All requests require `x-app-token` header.

## Rate Limiting

30 requests per minute per IP.
