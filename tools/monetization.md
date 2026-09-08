# Moonlight — Gelir modeli

Niş araştırması (Co–Star, The Pattern, Sanctuary, Nebula, Chani): hepsi **freemium + abonelik** kullanıyor. Ücretsiz günlük içerik + kilitli derin içerik. Nebula ek olarak **kredi/coin** ile tek tek fal sattırıyor (bizde zaten var). Sanctuary canlı okuma sattırıyor (ileride). Bizim edge: **stamp kartı** ile sadakat + oyunlaştırma — rakiplerde yok.

## Katmanlar

### 1) Ücretsiz (herkes)
- Günde **1-2 ücretsiz fal** (krediler her gün yenilenir — mevcut CreditManager).
- Ay fazı, gökyüzü olayları, temel doğum haritası (3 burç).
- Amaç: alışkanlık + geri dönüş. Paywall'a itmeden değeri göster.

### 2) Kredi paketleri (consumable IAP) — mevcut
- Ekstra fal isteyen ödesin. Tek seferlik, abonelik istemeyen için.
- Öneri paket: **10 kredi ~₺49**, **30 kredi ~₺119** (avantajlı), **100 kredi ~₺299** (en avantajlı).
- 1 fal = 1 kredi. Uzun/detaylı fal = 2-3 kredi.

### 3) Moonlight+ (abonelik) — ASIL gelir
- **Aylık ~₺89 / Yıllık ~₺499** (yıllık ~%50 avantaj, App Store standardı).
- İçerik:
  - Sınırsız günlük fal (veya günde bol kredi)
  - **Tam doğum haritası yorumu** (sadece 3 burç değil; gezegenler, evler)
  - Detaylı horary + tarot açılımları
  - **Hediye uzun okumalar**, faz bildirimleri, reklamsız
- Yıllıkta 3 gün deneme (trial) → dönüşüm artar.

### 4) Stamp kartı (sadakat + engagement) — Damla'nın fikri
- **Her 4 falda 1 fal hediye.** Kart 4 damga; dolunca 🎁 uzun okuma açılır.
- Doğrudan gelir değil ama: günlük dönüş + daha çok fal → daha çok kredi tüketimi → daha çok satın alma. Ödeme kararsızını da elde tutar.
- Ücretsiz kullanıcı da doldurabilir (ama daha yavaş); Moonlight+ üyesi **2x damga** → premium'a teşvik.

## Paywall yerleşimi (araştırma: erken ama yumuşak)
- Onboarding sonunda **soft paywall** (kapatılabilir): "Moonlight+ ile tam haritanı gör."
- Kredi bitince **NoCreditView** (mevcut) → "kredi al" veya "Moonlight+".
- Ana ekranda küçük **✦ kredi badge** (mevcut) → tıklayınca mağaza.
- Doğum haritasında "Tam yorumu aç" → premium kilidi.

## Öncelik
1. Krediler + kredi paketleri (var, App Store bağlan).
2. Stamp kartı (kolay, engagement).
3. Moonlight+ aboneliği (asıl para, StoreKit 2).
4. Trial + yıllık indirim.

## KVKK / App Store
- IAP fiyatları App Store Connect'ten, hardcode yok.
- Abonelik şartları + gizlilik politikası linkleri (mevcut legal bölümü).
- "Restore Purchases" (mevcut).
