# Roadmap

## Phase 1: Foundation
- [x] project setup (next.js, tailwind, fonts)
- [x] landing page
- [x] ios project setup (swiftui, xcode, xcodegen)
- [x] data models (moon phase, astro event)
- [x] moon phase calculation (local algorithm)
- [x] location manager
- [x] home view with moon scene, moon info, cosmic events
- [x] animated cloud layers, pixel art stars with twinkle
- [x] build and run on ios simulator

## Phase 2: Pixel Art Assets
- [x] integrate 107+ pixel art assets into xcassets
- [ ] (later) tarot card pixel art, hand-drawn by damla

## Phase 3: API Integrations
- [x] usno api integration (moon phase, illumination, moonrise/moonset)
- [x] hardcoded retrograde dates 2025-2026
- [x] real astronomical event data 2025-2026
- [x] freeastrologyapi.com integration for horary chart data

## Phase 4: Core Features
- [x] 3 tab layout (tarot <- home -> horary)
- [x] credit system (daily 3 free + storekit 2 purchases)
- [x] user profile (sun sign, rising, moon sign, birth time)
- [x] claude api service (haiku, embedded key, mystical personality)
- [x] tarot tab (question input, 78 card grid, 1-3 cards, premium spreads)
- [x] horary tab (question + chart data + claude interpretation)
- [x] settings (birth chart, credits, purchases)
- [x] settings gear on home

## Phase 5: Production Hardening
- [x] backend proxy for all api calls (production)
- [x] api key rotation and secure token management
- [x] purchase error handling with user feedback
- [x] privacy policy and terms of service in app
- [x] api error states with retry (home view)
- [x] location fallback indicator
- [ ] app icon (design, damla)
- [ ] credits storage in keychain (tamper resistance)
- [ ] host privacy policy and terms on github pages

## Phase 6: Polish
- [ ] premium spread implementations (celtic cross, 5-9 card)
- [ ] push notifications (moon phase changes)
- [ ] app store screenshots and metadata
