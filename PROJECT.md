# moonlight

Moon phases / horary / astrology tracking iOS app. Also Damla's architecture learning project: she writes the backend code, Claude teaches. Backend roadmap lives in her Obsidian.

## Status
Current phase: Launch
Last session: 2026-07-10 — widget extension + engagement prompts shipped, ship-check blockers fixed (privacy page live, birth data edit/delete, consent, privacy manifest), daily sky reading card, Moonlight+ monthly sub, history detail sheets, notification schedule.

## Roadmap
### Phase 1: Foundation
- [x] moon phase engine, charts via worker proxy (Damla's backend domain)
- [x] ChartCache: request coalescing, 10 min now-chart cache, natal forever, stale-on-failure, 15s timeout

### Phase 2: Core Features
- [x] MoonlightWidget (lock screen circular/inline/rectangular + home small, TR/EN)
- [x] Moonlight+ monthly subscription + consumable credits, entitlement checks on launch/purchase/restore
- [x] daily sky reading card (1 cached haiku call per user per day via existing proxy)

### Phase 3: Polish & Launch
- [ ] 1024 app icon into AppIcon.appiconset
- [ ] App Store Connect IAP: consumables credits5/10/15 + auto renewable com.damla.moonlight.plus.monthly
- [ ] confirm policy contact email damla@moonlight.app is real or replace
- [ ] Damla's assets, then submit

## Ideas
- Backend learning roadmap (Obsidian): Damla codes, Claude teaches only
- Move daily reading to a KV cached worker endpoint at scale (good learning exercise)
- Spotify integration idea parked in old notes

## Bugs / Issues
- Share card was removed on Damla's call (gold decor rejected); do not re-add without a concrete reference from her
- Type rules: no pixel fonts; Fraunces SemiBold titles, Inter body, static instances with full Turkish glyphs
