# Damla - Moonlight Asset Çizim Listesi

## Mevcut Assetler (zaten var, çizilmiş)

### Ay Karakterleri (8 faz, statik)
- `new_moon.png`
- `waxing_crescent.png`
- `first_quarter.png`
- `waxing_gibbous.png`
- `full_moon.png`
- `waning_gibbous.png`
- `last_quarter.png`
- `waning_crescent.png`

### Blink Animasyonu (8 faz x 4 frame = 32 asset, VAR)
- `blink_new_moon_frame00` → `frame03`
- `blink_waxing_crescent_frame00` → `frame03`
- `blink_first_quarter_frame00` → `frame03`
- `blink_waxing_gibbous_frame00` → `frame03`
- `blink_full_moon_frame00` → `frame03`
- `blink_waning_gibbous_frame00` → `frame03`
- `blink_last_quarter_frame00` → `frame03`
- `blink_waning_crescent_frame00` → `frame03`

### Glow Animasyonu (8 faz x 4 frame = 32 asset, VAR)
- `glow_new_moon_frame00` → `frame03`
- `glow_waxing_crescent_frame00` → `frame03`
- `glow_first_quarter_frame00` → `frame03`
- `glow_waxing_gibbous_frame00` → `frame03`
- `glow_full_moon_frame00` → `frame03`
- `glow_waning_gibbous_frame00` → `frame03`
- `glow_last_quarter_frame00` → `frame03`
- `glow_waning_crescent_frame00` → `frame03`

### Sahne Arka Planları (8 faz, VAR)
- `scene_new_moon`
- `scene_waxing_crescent`
- `scene_first_quarter`
- `scene_waxing_gibbous`
- `scene_full_moon`
- `scene_waning_gibbous`
- `scene_last_quarter`
- `scene_waning_crescent`

### Atmosfer (VAR)
- `atmospheric_cloud_1` → `cloud_6`, `cloud_purple`
- `atmospheric_sparkle_1` → `sparkle_3`
- `atmospheric_star_blue_1` → `blue_3`
- `atmospheric_star_gold_1` → `gold_3`
- `atmospheric_star_white_1` → `white_3`

### UI (VAR)
- `card_bg` - kart arka planı
- `card_bg_event` - event kart arka planı
- `badge_active` - aktif badge
- `icon_conjunction`, `icon_eclipse`, `icon_moonrise`, `icon_moonset`, `icon_opposition`, `icon_retrograde`, `icon_transit`
- `nav_dot_active`, `nav_dot_inactive`
- `app_icon`, `app_icon_large`
- `bg_sky_bright`, `bg_sky_dark`, `bg_sky_medium`
- `bg_full_moon` (v1-v7 varyasyonları)
- `full_moon_char`

---

## Çizilecekler (EKSİK)

### 1. Tarot Kart Arkası (1 asset)
- `tarot_card_back.png` - 64x96, tüm kartların arka yüzü, mistik pixel art desen

### 2. Tarot Kart Çerçevesi (1 asset)
- `tarot_card_frame.png` - 64x96, açılmış kartın çerçevesi (içi boş, üstüne text gelecek)

### 3. Element İkonları (4 asset)
- `icon_fire.png` - 16x16, ateş elementi
- `icon_earth.png` - 16x16, toprak elementi
- `icon_air.png` - 16x16, hava elementi
- `icon_water.png` - 16x16, su elementi

### 4. Settings İkonu (1 asset)
- `icon_settings.png` - 16x16, ayarlar dişli çark

### 5. Horary İkonları (2 asset)
- `icon_question.png` - 16x16, soru işareti (kristal küre tarzı)
- `icon_oracle.png` - 16x16, oracle/kehanet ikonu

### 6. Kredi İkonu (1 asset)
- `icon_credit.png` - 16x16, yıldız/coin şeklinde kredi ikonu

### 7. Close/Back İkonu (1 asset)
- `icon_close.png` - 16x16, kapat butonu

---

## Özet

| Kategori | Mevcut | Eksik |
|----------|--------|-------|
| Ay karakterleri | 8 | 0 |
| Blink animasyon | 32 | 0 |
| Glow animasyon | 32 | 0 |
| Sahne arka plan | 8 | 0 |
| Atmosfer | 16 | 0 |
| UI ikonlar | 11 | 7 |
| Tarot kartları | 0 | 2 |
| Element ikonları | 0 | 4 |
| **TOPLAM** | **107** | **13** |

## Stil Rehberi
- Boyutlar: ikonlar 16x16, kartlar 64x96
- Pixel art, chunky pixels, retro 8-bit
- Renk paleti: bg #0b0b2e, accent #FFE566, fire #FF6B6B, earth #34D399, air #A78BFA, water #60A5FA
- Şeffaf arka plan (PNG)
- Interpolation kapalı (.none) - kenarlar keskin kalacak
