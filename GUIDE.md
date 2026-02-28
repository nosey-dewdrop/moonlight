# 🌙 Moonlight — Command Guide

## Core Commands

### Start the project

npm run dev
Opens local server at http://localhost:3000
Code changes update automatically — no refresh needed.

### Install dependencies (first setup or after new package added)
npm install


### Add a new package
npm install package-name
# Example:
npm install suncalc


## Folder Structure

app/page.jsx         → "/" home page
app/layout.jsx       → shared template across all pages
app/journal/page.jsx → "/journal" page
app/horary/page.jsx  → "/horary" page
components/          → reusable UI pieces
public/              → images, icons
.env.local           → secret keys (API keys etc) — NEVER goes to GitHub
.gitignore           → files excluded from GitHub
package.json         → project dependencies list

## Routing Logic
Folder name = URL. No extra config needed.
app/page.jsx            → localhost:3000/
app/journal/page.jsx    → localhost:3000/journal
app/horary/page.jsx     → localhost:3000/horary
app/profile/page.jsx    → localhost:3000/profile


## Common Situations
Port 3000 busy       → npm run dev -- -p 3001
Missing package      → npm install
.env changed         → restart server (ctrl+c → npm run dev)

## Environment Variables (.env.local)

Secret keys go here. Never pushed to GitHub.
NEXT_PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJxxxxx
ANTHROPIC_API_KEY=sk-ant-xxxxx

NEXT_PUBLIC_ prefix = accessible in browser
No prefix = server-side only (more secure)
