-- Moonlight users database (Cloudflare D1)
-- Create:  npx wrangler d1 create moonlight_db
-- Apply:   npx wrangler d1 execute moonlight_db --remote --file=./schema.sql

CREATE TABLE IF NOT EXISTS users (
  id                TEXT PRIMARY KEY,
  apple_sub         TEXT UNIQUE,
  google_sub        TEXT UNIQUE,
  email             TEXT,
  sun_sign          TEXT,
  rising_sign       TEXT,
  moon_sign         TEXT,
  birth_time        TEXT,
  purchased_credits INTEGER NOT NULL DEFAULT 0,
  premium_until     TEXT,
  created_at        TEXT NOT NULL,
  updated_at        TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_users_apple  ON users (apple_sub);
CREATE INDEX IF NOT EXISTS idx_users_google ON users (google_sub);
