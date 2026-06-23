// Cloudflare Worker - API Proxy + Auth for Moonlight
// Deploy: npx wrangler deploy
// Secrets: npx wrangler secret put CLAUDE_API_KEY
//          npx wrangler secret put ASTROLOGY_API_KEY
//          npx wrangler secret put APP_TOKEN
//          npx wrangler secret put JWT_SECRET          (any long random string)
//          npx wrangler secret put GOOGLE_CLIENT_ID    (Google OAuth web client id)
// Vars:    APPLE_BUNDLE_ID = com.damla.moonlight   (set in wrangler.toml [vars])

const CLAUDE_URL = 'https://api.anthropic.com/v1/messages';
const ASTROLOGY_BASE = 'https://json.freeastrologyapi.com/western';
const APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys';
const APPLE_ISSUER = 'https://appleid.apple.com';
const SESSION_TTL = 60 * 60 * 24 * 90; // 90 days

export default {
  async fetch(request, env) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders() });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // App authentication - simple shared secret on every call
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

      // --- Auth routes ---
      if (path === '/api/auth/apple' && request.method === 'POST') {
        return handleAppleAuth(request, env);
      }
      if (path === '/api/auth/google' && request.method === 'POST') {
        return handleGoogleAuth(request, env);
      }
      if (path === '/api/me' && request.method === 'GET') {
        return handleMe(request, env);
      }
      if (path === '/api/profile' && request.method === 'POST') {
        return handleProfileUpdate(request, env);
      }

      // --- Proxy routes ---
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

// ============================================================
// Auth
// ============================================================

async function handleAppleAuth(request, env) {
  const { identityToken } = await request.json();
  if (!identityToken) return jsonResponse({ error: 'Missing identityToken' }, 400);

  const claims = await verifyAppleToken(identityToken, env);
  if (!claims) return jsonResponse({ error: 'Invalid Apple token' }, 401);

  const user = await upsertUser(env, { provider: 'apple', sub: claims.sub, email: claims.email });
  const token = await signSession(user.id, env);
  return jsonResponse({ token, user: publicUser(user) });
}

async function handleGoogleAuth(request, env) {
  const { idToken } = await request.json();
  if (!idToken) return jsonResponse({ error: 'Missing idToken' }, 400);

  const claims = await verifyGoogleToken(idToken, env);
  if (!claims) return jsonResponse({ error: 'Invalid Google token' }, 401);

  const user = await upsertUser(env, { provider: 'google', sub: claims.sub, email: claims.email });
  const token = await signSession(user.id, env);
  return jsonResponse({ token, user: publicUser(user) });
}

async function handleMe(request, env) {
  const userId = await requireSession(request, env);
  if (!userId) return jsonResponse({ error: 'Unauthorized' }, 401);
  const user = await getUser(env, userId);
  if (!user) return jsonResponse({ error: 'Not found' }, 404);
  return jsonResponse({ user: publicUser(user) });
}

async function handleProfileUpdate(request, env) {
  const userId = await requireSession(request, env);
  if (!userId) return jsonResponse({ error: 'Unauthorized' }, 401);

  const body = await request.json();
  const now = new Date().toISOString();
  await env.DB.prepare(
    `UPDATE users SET sun_sign = ?, rising_sign = ?, moon_sign = ?, birth_time = ?, updated_at = ? WHERE id = ?`
  ).bind(
    body.sunSign ?? null,
    body.risingSign ?? null,
    body.moonSign ?? null,
    body.birthTime ?? null,
    now,
    userId
  ).run();

  const user = await getUser(env, userId);
  return jsonResponse({ user: publicUser(user) });
}

// ============================================================
// User store (D1)
// ============================================================

async function upsertUser(env, { provider, sub, email }) {
  const column = provider === 'apple' ? 'apple_sub' : 'google_sub';
  const existing = await env.DB.prepare(`SELECT * FROM users WHERE ${column} = ?`).bind(sub).first();
  if (existing) {
    if (email && !existing.email) {
      await env.DB.prepare(`UPDATE users SET email = ?, updated_at = ? WHERE id = ?`)
        .bind(email, new Date().toISOString(), existing.id).run();
    }
    return existing;
  }

  const id = crypto.randomUUID();
  const now = new Date().toISOString();
  await env.DB.prepare(
    `INSERT INTO users (id, ${column}, email, purchased_credits, created_at, updated_at)
     VALUES (?, ?, ?, 0, ?, ?)`
  ).bind(id, sub, email ?? null, now, now).run();

  return await getUser(env, id);
}

async function getUser(env, id) {
  return await env.DB.prepare(`SELECT * FROM users WHERE id = ?`).bind(id).first();
}

function publicUser(u) {
  return {
    id: u.id,
    email: u.email,
    sunSign: u.sun_sign,
    risingSign: u.rising_sign,
    moonSign: u.moon_sign,
    birthTime: u.birth_time,
    purchasedCredits: u.purchased_credits,
    premiumUntil: u.premium_until,
    isPremium: u.premium_until ? new Date(u.premium_until) > new Date() : false,
  };
}

// ============================================================
// Token verification
// ============================================================

async function verifyAppleToken(token, env) {
  const parts = token.split('.');
  if (parts.length !== 3) return null;

  const header = JSON.parse(b64urlToString(parts[0]));
  const payload = JSON.parse(b64urlToString(parts[1]));

  // Fetch Apple public keys and find the matching one
  const res = await fetch(APPLE_KEYS_URL);
  const { keys } = await res.json();
  const jwk = keys.find((k) => k.kid === header.kid);
  if (!jwk) return null;

  const key = await crypto.subtle.importKey(
    'jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']
  );
  const data = new TextEncoder().encode(`${parts[0]}.${parts[1]}`);
  const sig = b64urlToBytes(parts[2]);
  const valid = await crypto.subtle.verify('RSASSA-PKCS1-v1_5', key, sig, data);
  if (!valid) return null;

  const bundleId = env.APPLE_BUNDLE_ID || 'com.damla.moonlight';
  if (payload.iss !== APPLE_ISSUER) return null;
  if (payload.aud !== bundleId) return null;
  if (payload.exp * 1000 < Date.now()) return null;

  return { sub: payload.sub, email: payload.email };
}

async function verifyGoogleToken(idToken, env) {
  // Google validates the signature and returns the claims for us.
  const res = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(idToken)}`);
  if (!res.ok) return null;
  const payload = await res.json();

  if (payload.iss !== 'https://accounts.google.com' && payload.iss !== 'accounts.google.com') return null;
  if (env.GOOGLE_CLIENT_ID && payload.aud !== env.GOOGLE_CLIENT_ID) return null;
  if (Number(payload.exp) * 1000 < Date.now()) return null;

  return { sub: payload.sub, email: payload.email };
}

// ============================================================
// Session JWT (HS256, signed by us)
// ============================================================

async function signSession(userId, env) {
  const header = { alg: 'HS256', typ: 'JWT' };
  const now = Math.floor(Date.now() / 1000);
  const payload = { sub: userId, iat: now, exp: now + SESSION_TTL };
  const head = stringToB64url(JSON.stringify(header));
  const body = stringToB64url(JSON.stringify(payload));
  const sig = await hmac(`${head}.${body}`, env.JWT_SECRET);
  return `${head}.${body}.${sig}`;
}

async function requireSession(request, env) {
  const auth = request.headers.get('Authorization') || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : null;
  if (!token) return null;

  const parts = token.split('.');
  if (parts.length !== 3) return null;
  const expected = await hmac(`${parts[0]}.${parts[1]}`, env.JWT_SECRET);
  if (expected !== parts[2]) return null;

  const payload = JSON.parse(b64urlToString(parts[1]));
  if (payload.exp * 1000 < Date.now()) return null;
  return payload.sub;
}

async function hmac(data, secret) {
  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(secret),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign('HMAC', key, new TextEncoder().encode(data));
  return bytesToB64url(new Uint8Array(sig));
}

// ============================================================
// Base64url helpers
// ============================================================

function stringToB64url(str) {
  return bytesToB64url(new TextEncoder().encode(str));
}
function bytesToB64url(bytes) {
  let bin = '';
  for (let i = 0; i < bytes.length; i++) bin += String.fromCharCode(bytes[i]);
  return btoa(bin).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}
function b64urlToBytes(b64url) {
  const b64 = b64url.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(b64url.length / 4) * 4, '=');
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}
function b64urlToString(b64url) {
  return new TextDecoder().decode(b64urlToBytes(b64url));
}

// ============================================================
// Existing proxies
// ============================================================

async function handleClaude(request, env) {
  const body = await request.json();
  if (!body.messages || !Array.isArray(body.messages)) {
    return jsonResponse({ error: 'Invalid request' }, 400);
  }
  body.model = 'claude-haiku-4-5-20251001';
  body.max_tokens = Math.min(body.max_tokens || 1024, 2048);

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
  const allowed = ['/planets', '/houses', '/aspects'];
  if (!allowed.includes(endpoint)) {
    return jsonResponse({ error: 'Invalid endpoint' }, 400);
  }
  const response = await fetch(`${ASTROLOGY_BASE}${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'x-api-key': env.ASTROLOGY_API_KEY },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  return jsonResponse(data, response.status);
}

function jsonResponse(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', ...corsHeaders() },
  });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, x-app-token, Authorization',
  };
}
