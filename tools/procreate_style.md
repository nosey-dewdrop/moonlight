# Moonlight — Procreate çizim rehberi

Amaç: tüm assetler tek elden çıkmış gibi dursun. Mevcut gök, ay, bulut, pırıltı ile aynı dünya.

## Genel stil
- **Sulu boya + kuru boya (crayon) karışımı.** Yumuşak, masum, çaylak — kusurlu kenar iyidir, çok temiz/vektör olmasın.
- **Kağıt her zaman görünür.** Doku bırak, düz dijital dolgu yapma.
- **İnce ama net kontur.** Ay ve buluttaki gibi hafif, koyu lacivert/altın el çizimi çizgi. Sert siyah dış çizgi YOK.
- **Renkler:** zemin lacivert `#0B0B2E`, altın `#FFE566`, lila/periwinkle `#B9B6E8`. Aksesuar: soft mavi, sıcak krem. Kırmızı/yeşil kullanma.
- **Boyut:** her asset kare tuval, min **2048×2048**, 300 DPI. Şeffaf zemin (arka planı boş bırak, katmanı silme).

## Kağıt kurulumu (bir kere)
- Tuval: 2048×2048, DPI 300.
- En alta 1 katman: Procreate "Paper" dokusundan biriyle çok hafif gri-krem doku (opaklık ~%8). Assetin altına değil, referans için; export'ta kapat (şeffaf PNG lazım).

## Fırçalar (Procreate stok — para gerektirmez)
| İş | Fırça (set) | Not |
|---|---|---|
| Sulu boya yıkama/gövde | **Watercolor → "Wet Acrylic"** veya **"Flat Watercolor"** | ana dolgu, hafif bas, üst üste geçir |
| Yumuşak kenar/hale | **Watercolor → "Water Bleed"** | ay ışığı, bulut kenarı |
| Kuru boya doku (crayon) | **Sketching → "Procreate Pencil"** veya **Charcoals → "Vine Charcoal"** düşük opaklık | pırıltı/yıldız dokusu, gök granülü |
| İnce kontur | **Inking → "Dry Ink"** ince uçlu | ay, bulut, kedi çizgisi |
| Altın serpme | **Spraypaints → "Flick"** veya **"Splatter"** altın renk | yıldız tozu, gök altın damarları |

İstersen ücretli: "Georg von Westphalen Watercolor" seti çok uyar ama şart değil, stok yeter.

## Asset asset notlar
- **Ay fazları (8):** aynı ay karakteri, sadece aydınlık kısım değişir. Gövdeyi Flat Watercolor ile krem/altın boya, karanlık kısmı lacivert bırak, terminatörü Water Bleed ile yumuşat. Dolunaydaki ince altın konturu koru.
- **Bulut:** Water Bleed ile 2-3 katman periwinkle, altına hafif krem ışık. İnce Dry Ink kontur. Biri büyük, birkaçı küçük çiz — sağa/sola bakan versiyonlar (aynala).
- **Pırıltı/yıldız:** kuru boya dokusuyla altın dört köşe. **Arkasına mavi leke KOYMA** (uygulamada gökle çakışıyor) — sadece altın şekil, şeffaf zemin.
- **Sihirli kedi (maskot):** minik, sevimli, sakin gözler. Lacivert-altın paleti. İki poz: (1) sakin otururken, (2) kafasında soru işareti (doğum saati ipucu için). İnce Dry Ink kontur + Flat Watercolor dolgu.
- **İkonlar (ayar, profil, kredi, hediye…):** tek renk altın, ince kuru boya çizgi, minimal. Watercolour zorlarsa düz altın crayon çizgi yeter.

## Export
- Katman > arka plan kapalı > **PNG** (şeffaf).
- İsimlendirme: `full_moon.png`, `waxing_crescent.png`, `cloud_1.png`, `sparkle_gold.png`, `cat_helper.png`, `cat_helper_question.png` … (asset listesindeki adlarla birebir).
- Hepsini `~/moonlight/assets_raw/` içine at; ben işleyip app'e koyarım.
