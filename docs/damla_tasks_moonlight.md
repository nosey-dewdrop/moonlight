# Moonlight çizim listesi

Pixel artı bırakıyoruz. Yeni stil sıcak, el çizimi, hafif ışıltılı (watercolour). Keskin köşe / pixel hissi yok. Yumuşak gölge, yumuşak geçiş.

Renkler: koyu lacivert zemin (0B0B2E), altın sarısı vurgu (FFE566), elementler pastel (ateş kırmızı, toprak yeşil, hava mor, su mavi).

Arka plan: **şeffaf** = PNG, arka plan boş, gökyüzünün üstüne biner. **dolu** = kenardan kenara renkli, şeffaflık yok. Her satırda tek tek yazıyor.

Hepsini büyük çiz, ben küçültürüm. Watercolour'a geçince render'ı smooth'a alacağım.

**Animasyon:** blink/glow frame ÇİZME. Ay fazları statik. Hareket, pırıltıları (sparkle) ayın üstünde koddan kaydırarak gelecek. Eski 64 frame iptal.

---

## Ay fazları

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| new_moon | 1024x1024 | şeffaf | yeni ay karakteri, yüzlü |
| waxing_crescent | 1024x1024 | şeffaf | büyüyen hilal |
| first_quarter | 1024x1024 | şeffaf | ilk dördün |
| waxing_gibbous | 1024x1024 | şeffaf | büyüyen şişkin ay |
| full_moon | 1024x1024 | şeffaf | dolunay |
| waning_gibbous | 1024x1024 | şeffaf | küçülen şişkin ay |
| last_quarter | 1024x1024 | şeffaf | son dördün |
| waning_crescent | 1024x1024 | şeffaf | küçülen hilal |

## Bulutlar

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| atmospheric_cloud_1 | 1024x512 | şeffaf | yumuşak bulut |
| atmospheric_cloud_2 | 1024x512 | şeffaf | yumuşak bulut |
| atmospheric_cloud_3 | 1024x512 | şeffaf | yumuşak bulut |
| atmospheric_cloud_4 | 1024x512 | şeffaf | yumuşak bulut |
| atmospheric_cloud_5 | 1024x512 | şeffaf | yumuşak bulut |
| atmospheric_cloud_6 | 1024x512 | şeffaf | yumuşak bulut |

## Yıldızlar

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| atmospheric_star_blue_1 | 256x256 | şeffaf | mavi yıldız |
| atmospheric_star_gold_2 | 256x256 | şeffaf | altın yıldız |
| atmospheric_star_white_2 | 256x256 | şeffaf | beyaz yıldız |

## Işıltılar (animasyonu bunlar taşıyacak)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| sparkle_blue | 256x256 | şeffaf | dört köşeli mavi twinkle |
| sparkle_gold | 256x256 | şeffaf | dört köşeli altın twinkle |

## Gezegenler

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| planet_jupiter | 512x512 | şeffaf | jüpiter |
| planet_mars | 512x512 | şeffaf | mars |
| planet_neptune | 512x512 | şeffaf | neptün |
| planet_saturn | 512x512 | şeffaf | satürn, halkalı |
| planet_venus | 512x512 | şeffaf | venüs |

## Olay ikonları (altın tonlu, aynı çizgi kalınlığı)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| icon_conjunction | 256x256 | şeffaf | kavuşum |
| icon_eclipse | 256x256 | şeffaf | tutulma |
| icon_moonrise | 256x256 | şeffaf | ay doğuşu |
| icon_moonset | 256x256 | şeffaf | ay batışı |
| icon_opposition | 256x256 | şeffaf | karşıtlık |
| icon_retrograde | 256x256 | şeffaf | retro |
| icon_transit | 256x256 | şeffaf | geçiş |

## Tab ikonları

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| tab_tarot | 256x256 | şeffaf | kart motifi |
| tab_horary | 256x256 | şeffaf | kristal küre |

## Gökyüzü arka planları (tam ekran)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| bg_sky_bright | 1242x2688 | dolu | aydınlık gökyüzü |
| bg_sky_medium | 1242x2688 | dolu | alacakaranlık |
| bg_sky_dark | 1242x2688 | dolu | gece |

## Sahne arka planları (her faza özel — istersen 3 gökyüzüyle yetinip atlayabiliriz, karar senin)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| scene_new_moon | 1242x2688 | dolu | yeni ay sahnesi |
| scene_waxing_crescent | 1242x2688 | dolu | büyüyen hilal sahnesi |
| scene_first_quarter | 1242x2688 | dolu | ilk dördün sahnesi |
| scene_waxing_gibbous | 1242x2688 | dolu | büyüyen şişkin sahne |
| scene_full_moon | 1242x2688 | dolu | dolunay sahnesi |
| scene_waning_gibbous | 1242x2688 | dolu | küçülen şişkin sahne |
| scene_last_quarter | 1242x2688 | dolu | son dördün sahnesi |
| scene_waning_crescent | 1242x2688 | dolu | küçülen hilal sahnesi |

## Logo ve app icon

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| logo | 1024x1024 | şeffaf | ay + Moonlight yazısı |
| app_icon | 1024x1024 | dolu | kenardan kenara dolu kare |
| LaunchBg | 1242x2688 | dolu | açılış zemini (tek renk 0B0B2E olur) |

---

## YENİ: Hesap + bulut akışı

### Sihirli kedi helper (KAHRAMAN)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| cat_helper | 1024x1024 | şeffaf | yardımcı kedi, sakin/idle, app maskotu |
| cat_helper_question | 1024x1024 | şeffaf | kafasında soru işareti, doğum saati ipucu baloncuğunu açar |

### Giriş ikonları (Apple butonu native, çizilmez)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| icon_google | 256x256 | şeffaf | Google "G", tanınır |
| icon_mail | 256x256 | şeffaf | zarf, mail ile giriş |

### Doğum tarihi ve saati ekranı

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| icon_calendar | 256x256 | şeffaf | doğum tarihi |
| icon_clock | 256x256 | şeffaf | doğum saati |
| checkbox_on | 256x256 | şeffaf | "saati bilmiyorum" işaretli |
| checkbox_off | 256x256 | şeffaf | "saati bilmiyorum" boş |

### Hesap ve ayarlar

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| icon_settings | 256x256 | şeffaf | dişli |
| icon_account | 256x256 | şeffaf | kullanıcı/profil |
| icon_logout | 256x256 | şeffaf | çıkış |
| icon_close | 256x256 | şeffaf | kapat |

### Hediye okuma (9 falda bir)

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| icon_gift | 256x256 | şeffaf | hediye |
| card_longread | 768x1152 | şeffaf | dikey kart/parşömen, "bu özel" hissi |

### Kredi ve gizlilik

| Asset | Boyut | Arka plan | Açıklama |
|---|---|---|---|
| icon_credit | 256x256 | şeffaf | yıldız/coin |
| icon_shield | 256x256 | şeffaf | KVKK/gizlilik onay ekranı |

---

## Tarot destesi (ayrı karar)

78 kartlık tam deste zaten var (22 major + 56 minor: cups/pentacles/swords/wands) + eksik `tarot_card_back`, `tarot_card_frame`. Hepsi **şeffaf**. Büyük batch — watercolour'a hepsini yeniden mi çizeriz yoksa şimdilik mevcut mu kalır, ayrı karar. Önce çekirdek set + hesap akışı.

---

## Çizimler bitince yapılacaklar
- Landing page
- Üyelik girişi (Apple / Google / mail) ve doğum bilgisiyle birth chart
- Bulut senkronu (fal geçmişi ve notlar cihazlar arası)
- 9 falda bir hediye uzun okuma
- Faz değişimi bildirimi
- Yorum yazısının fontunu düzeltmek
- iOS yayını (KVKK onayı, privacy policy)
