# devlog.md — instagram build-in-public reels queue

> Format (Damla): minik parçalar, her ünite 30-60 sn'lik hook'lu reels (post/carousel de olur). Anlatım: "bugün şunu değiştirdim arkadaşlar, çünkü şöyle bir sorun vardı" + numaralı neden/karar. Bunlar iskelet, Damla kendi ağzıyla anlatır. Her satır gerçek git geçmişinden. Uzun essay versiyonları linkedin.md'de, projeye bağsız genel konular ~/damla_projects_2026/damla-icerik.md'de.
> görsel notları: [ekran] = uygulama ekran kaydı, [kod] = worker.js / schema.sql, [terminal] = wrangler / build çıktısı, [diyagram] = katman çizimi.

## seri A — mimari öğrenme yolculuğu

A1 · HOOK: "bir astroloji uygulaması yapmadım, arkasındaki sunucuyu öğrenmek için bahane yaptım."
- gerçek amaç: web'de CRUD yığmaktan sıkıldım, sistem mimarisi / backend öğrenmek istedim.
- kural: backend'i BEN yazacağım, mentorum sadece anlatacak. öğrenmek delege edilmez.
- **EN (text-on-video):** "the app was the excuse. the backend was the lesson."

A2 · HOOK: "ilk hatam: API anahtarımı telefonun içine koymak."
- tarot okumaları için Claude API lazımdı. anahtarı uygulamanın içine gömdüm. çalıştı.
- ama bir mobil app'i herkes açıp içindeki anahtarı çıkarır — o anahtar benim faturamı ödüyor.
- ders 1: istemciye SIR koyamazsın. [kod]
- **EN (text-on-video):** "you can't put a secret in an app anyone can open."

A3 · HOOK: "bugün ilk kez 'backend'i kendim yazdım: bir proxy kurdum."
- cihaz ile Anthropic'in arasına kendi Cloudflare Worker'ımı koydum.
- anahtarlar artık Worker secret'larında, cihazda değil. cihazda sadece bir 'app token' kaldı.
- üstüne IP başına dakikada 30 istek rate-limit. cihazdan doğrudan anahtar kullanımını tamamen sildim. [kod]
- **EN (text-on-video):** "keys off the device. a proxy in between. this is where backend starts."

A4 · HOOK: "koda tarih gömmüştüm — hızlıydı ama yalandı."
- gezegen retrograde'larını ve tutulma tarihlerini koda hardcode etmiştim.
- düzelttim: canlı retrograde freeastrologyapi'den, tutulmalar NASA verisiyle 2027'ye kadar doğrulandı, hardcode silindi.
- ay evresinde de bug vardı: 'closestphase' okuyordum, doğrusu 'curphase'di. uygulamanın tek işi bunu doğru söylemek. [ekran]
- **EN (text-on-video):** "hardcoded data is a lie with a deadline."

## seri B — auth'u sıfırdan yazmak

B1 · HOOK: "auth'u kütüphaneyle geçebilirdim. kendim yazdım, çünkü öğrenmek istiyordum."
- gerçek kullanıcı için bir veritabanı lazımdı. Cloudflare D1 (SQLite) seçtim, Worker zaten oradaydı.
- users tablosunu kendim tasarladım: apple_sub / google_sub'a unique index, upsert idempotent. [kod]
- **EN (text-on-video):** "auth is where a system breaks. so I wrote it by hand.

B2 · HOOK: "Apple giriş token'ını kütüphanesiz doğruladım — en zoru buydu."
- Apple'ın identity token'ı bir JWT. token'ı üçe böldüm, Apple'ın public key'lerini çektim.
- 'kid'e göre doğru anahtarı buldum, WebCrypto ile RSA imzasını doğruladım, sonra iss/aud/exp kontrol ettim.
- 'imzayı doğrula' cümlesini artık ezberden değil byte'ından biliyorum. [kod]
- **EN (text-on-video):** "verifying a signature, one byte at a time."

B3 · HOOK: "kendi oturum token'ımı kendi elimle imzaladım."
- kullanıcı doğrulandıktan sonra 90 günlük HS256 JWT'mi ürettim.
- base64url encode'u, HMAC-SHA256 imzası, hepsi elle. her istekte imzayı yeniden hesaplayıp karşılaştırıyorum.
- framework'ün 3 satırda sakladığını 30 satırda açtım — şimdi ne olduğunu biliyorum. [kod]
- **EN (text-on-video):** "the library hides it in 3 lines. I opened all 30."

B4 · HOOK: "yazdığım backend şu an uyuyor. saklamıyorum."
- kod canlı, D1 şeması hazır, auth route'ları duruyor — ama uygulamada henüz giriş ekranı yok.
- ship-check bunu 'dormant auth endpoints' diye yazdı. öğrenme projesinin doğası bu: sistemi anlamak için yazdım, ürün oraya gelmedi.
- ve öğrendim: giriş ekranını koyduğum gün Apple 'uygulama-içi hesap silme'yi zorunlu kılıyor. sonraki iş baştan belli. [ekran]
- **EN (text-on-video):** "I wrote a backend that's still asleep. that's honest learning."

## seri C — dış dünyaya karşı mimari

C1 · HOOK: "dış API yavaştı, suç bende değildi ama sorumluluk benim."
- astroloji chart'ları bazen saniyelerce takılıyor, bazen düşüyordu. kullanıcı için: uygulamam donmuş görünüyor.
- backend'i (dış servis) değiştiremem ama istemci mimarisini değiştirebilirim: ChartCache yazdım. [kod]
- **EN (text-on-video):** "you can't fix their server. you can armor your client."

C2 · HOOK: "ChartCache'in üç ilkesi: aynı isteği iki kez yapma, doğum haritasını sonsuza cache'le, servis ölürse bayat veriyi ver."
- request coalescing: aynı chart aynı anda iki kez istenirse tek isteğe iliştir.
- akıllı TTL: 'şimdi' chart'ı 10 dk, natal chart sonsuza kadar (doğum haritan değişmez).
- stale-on-failure: upstream düşerse hata gösterme, elindeki bayat veriyi ver. üstüne 15 sn timeout.
- **EN (text-on-video):** "old correct data beats fresh errors."

C3 · HOOK: "günde bir kez Claude'a soruyorum, her açılışta değil — hem hız hem para."
- ana ekranda günlük gökyüzü okuması var. her açılışta yeni çağrı yavaş VE pahalı olurdu.
- karar: kullanıcı başına günde bir, dile göre cache'lenmiş tek çağrı. not: ölçekte KV-cache'li Worker endpoint'e taşı (iyi öğrenme egzersizi). [kod]
- **EN (text-on-video):** "one call a day beats one call a launch."

## seri D — dürüstlük ve tasarım

D1 · HOOK: "uygulamam üç estetikten geçti, iki kez fikir değiştirdim."
- önce SF Symbols. sonra tam piksel-sanat dönemi (piksel yıldızlar, Pixelify font). sonra karar: piksel font OKUNMUYOR.
- hepsini geri aldım: Fraunces başlık, Inter gövde, Türkçe glifli statik font. doğru tasarım denemeden bilinmiyor. [ekran]
- **EN (text-on-video):** "three aesthetics, two pivots. that's how you find the right one."

D2 · HOOK: "bir özelliği doğduğu gece sildim."
- okuma paylaşımı için altın çerçeveli, yıldız alanlı kart yaptım — mistik yükleme metinleri, tam paket.
- Damla altın süslemeyi reddetti. aynı gece sildim. yapabilmek, yapılmalı demek değil. [ekran]
- **EN (text-on-video):** "being able to build it isn't a reason to ship it."

D3 · HOOK: "onboarding'im 'verini sil' diyordu ama silme butonu YOKTU."
- ship-check yakaladı: UserProfile.reset() kodda vardı, hiçbir ekrandan çağrılmıyordu.
- uygulamam reklamını yaptığı hakkı vermiyordu — hem CRUD hem KVKK ihlali. aynı oturumda düzelttim: 'düzenle' + 'verilerimi sil' (onaylı).
- ders: öğrenme projesi de gerçek kullanıcıya çıkıyorsa 'sadece öğreniyorum' mazeret değil. [ekran]
- **EN (text-on-video):** "'delete anytime' with no delete button is a lie."

D4 · HOOK: "org taşınınca gizlilik politikam öldü — App Store bunu affetmiyor."
- politika ve şartlar URL'leri 404 vermeye başlamıştı. uygulama içindeki linkler ölü sayfalara gidiyordu.
- GitHub Pages açtım, linkleri düzelttim, politikayı gerçeğe uydurdum, KVKK/GDPR hakları bölümü ekledim. privacy manifest'i tamamladım.
- **EN (text-on-video):** "a dead privacy link is a rejected app."
