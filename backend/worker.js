// Cloudflare Worker - API Proxy for Moonlight
// Deploy: npx wrangler deploy
// Set secrets: npx wrangler secret put CLAUDE_API_KEY
//              npx wrangler secret put ASTROLOGY_API_KEY

const CLAUDE_URL = 'https://api.anthropic.com/v1/messages';
const ASTROLOGY_BASE = 'https://json.freeastrologyapi.com/western';

export default {
  async fetch(request, env) {
    // CORS
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: corsHeaders(),
      });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // App authentication - simple shared secret
      const appToken = request.headers.get('x-app-token');
      if (appToken !== env.APP_TOKEN) {
        return jsonResponse({ error: 'Unauthorized' }, 401);
      }

      // Rate limiting by IP
      const ip = request.headers.get('cf-connecting-ip') || 'unknown';
      const rateLimitKey = `rate:${ip}:${Math.floor(Date.now() / 60000)}`;
      const current = await env.RATE_LIMIT?.get(rateLimitKey);
      const count = current ? parseInt(current) : 0;

      if (count > 30) {
        return jsonResponse({ error: 'Rate limit exceeded. Please wait.' }, 429);
      }
      await env.RATE_LIMIT?.put(rateLimitKey, String(count + 1), { expirationTtl: 120 });

      // Route
      if (path === '/api/claude' && request.method === 'POST') {
        return handleClaude(request, env);
      }
      if (path.startsWith('/api/astrology/') && request.method === 'POST') {
        const endpoint = path.replace('/api/astrology', '');
        return handleAstrology(request, env, endpoint);
      }

      return jsonResponse({ error: 'Not found' }, 404);
    } catch (err) {
      return jsonResponse({ error: 'Internal error' }, 500);
    }
  },
};

async function handleClaude(request, env) {
  const body = await request.json();

  // Validate required fields
  if (!body.messages || !Array.isArray(body.messages)) {
    return jsonResponse({ error: 'Invalid request' }, 400);
  }

  // Enforce our limits
  body.model = 'claude-haiku-4-5-20251001';
  body.max_tokens = Math.min(body.max_tokens || 1024, 1024);

  const response = await fetch(CLAUDE_URL, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      'x-api-key': env.CLAUDE_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify(body),
  });

  const data = await response.json();
  return jsonResponse(data, response.status);
}

async function handleAstrology(request, env, endpoint) {
  const body = await request.json();

  // Validate endpoint
  const allowed = ['/planets', '/houses', '/aspects'];
  if (!allowed.includes(endpoint)) {
    return jsonResponse({ error: 'Invalid endpoint' }, 400);
  }

  const response = await fetch(`${ASTROLOGY_BASE}${endpoint}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': env.ASTROLOGY_API_KEY,
    },
    body: JSON.stringify(body),
  });

  const data = await response.json();
  return jsonResponse(data, response.status);
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'Content-Type': 'application/json',
      ...corsHeaders(),
    },
  });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, x-app-token',
  };
}
