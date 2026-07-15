# linkedin.md — build-in-public essay stock

> Format (Damla): numbered build chain, each step a DECISION (what + why + result). 300-500+ words, Turkish, honest — downfalls and pivots are not hidden. One essay per major turning point. The prose itself is in Damla's voice; these are skeleton/material. Every line comes from the real git history; numbers are real. Reels versions live in devlog.md, project-agnostic general topics in ~/damla_projects_2026/damla-icerik.md.

moonlight, iki iş yapıyor: bir yandan ay evresi / horary / astroloji takip eden bir iOS uygulaması, öte yandan Damla'nın **mimari öğrenme projesi** — backend kodunu Damla yazıyor, Claude sadece öğretiyor, onun yerine yazmıyor. Bu yüzden essay'lerin çoğu bir öğrenme hikayesi.

---

## Essay 1 — "Astroloji uygulaması bahaneydi, asıl proje backend öğrenmekti"

1. **Başlangıç, dürüst niyet.** Şubat sonunda repo'yu bir müzik çalma listesiyle açtım — ilk commit'lerden biri düpedüz "şu an dinlediğim şarkıyı push'luyorum, Franz Ferdinand". moonlight bir ay evresi uygulaması olacaktı: ay hangi evrede, göksel olaylar ne zaman, güzel bir gökyüzü. Ama gerçek sebebim farklıydı. Web'de CRUD ve SaaS yığmaktan sıkılmıştım; **sistem mimarisi**, backend, "gerçek bir sunucu nasıl kurulur" öğrenmek istiyordum. Kural şuydu: backend'i BEN yazacağım, mentor sadece anlatacak, benim yerime yazmayacak. Öğrenmek delege edilemez.

2. **İlk hata: anahtarı cihaza gömmek.** Tarot ve horary için Claude API'ye ihtiyacım vardı. İlk sürümde API anahtarını uygulamanın içine, "secrets"a koydum. Çalışıyordu. Ama bir mobil binary'yi herkes açıp içindeki anahtarı çıkarabilir — bu anahtar benim faturamı ödüyor. Mimari ders numarası bir: **istemciye sır koyamazsın.** Çözüm bir proxy: cihaz ile Anthropic arasına kendi sunucumu koydum.

3. **Cloudflare Worker'ı elimle yazdım.** Bütün API çağrılarını (Claude + astroloji) bir Cloudflare Worker üzerinden geçirdim. Anahtarlar artık Worker secret'larında, cihazda değil. Cihazda sadece bir "app token" kaldı. Worker aynı zamanda IP başına dakikada 30 istekle rate-limit yapıyor (KV ile), CORS başlıklarını yönetiyor. Uygulamadan doğrudan anahtar kullanımını tamamen sildim. İlk kez "backend" dediğim şey benim yazdığım, deploy ettiğim, sırları benim tuttuğum bir şeydi.

4. **İkinci hata ve düzeltmesi: retrograde'ları hardcode etmek.** Başta gezegen retrograde'larını ve bazı tarihleri koda gömmüştüm — hızlı ama yalan. Sonra freeastrologyapi'den canlı retrograde çektim, tutulma tarihlerini NASA verisiyle 2027'ye kadar doğruladım, hardcode'ları sildim. Ay evresinde de bir bug vardı: USNO'dan "closestphase" okuyordum, doğrusu "curphase"di. Küçük ama uygulamanın tek işi ay evresini doğru söylemek.

5. **Neden anlatıyorum.** Çünkü bu proje bana "app yapmayı" değil, **bir sistemin katmanlarını** öğretti: istemci, proxy, sır yönetimi, hız sınırı, dış API'lerin yalancılığı. Astroloji sadece üstündeki temaydı. Gömülü anahtardan Worker proxy'ye geçtiğim gün, ilk defa "geliştirici" değil "mimar" gibi düşündüm. Öğrenmek için sıkıcı bir to-do app kurabilirdim; onun yerine gökyüzünü kurdum, çünkü öğrenmenin de bir ruhu olmalı.

---

## Essay 2 — "Backend'i kendim yazdım: D1, JWT ve oturum"

1. **Bir sonraki katman: kullanıcılar.** Proxy çalışıyordu ama uygulamanın hafızası yoktu; herkes anonimdi. Gerçek bir arka uç için kullanıcı deposu lazımdı. Burada mentor kuralı devreye girdi: **kodu ben yazacağım.** Auth, herkesin "kütüphane çağır, bitti" sandığı ama aslında sistemin en tehlikeli parçası. Tam da bu yüzden elimle yazmak istedim.

2. **D1'i seçtim (Cloudflare'in SQLite'ı).** Worker zaten Cloudflare'deydi, veritabanını da yanına koydum. `users` tablosunu kendim tasarladım: id, apple_sub, google_sub, email, burç bilgileri, satın alınan kredi, premium bitiş tarihi. Apple ve Google sub'larına unique index koydum ki aynı kişi iki kere kayıt olmasın. `upsertUser` yazdım: kullanıcı varsa döndür, yoksa oluştur — idempotent olması lazımdı çünkü aynı token'la iki kere giriş gelebilir.

3. **Apple token'ını sıfırdan doğruladım.** En zoru buydu. Apple'ın identity token'ı bir JWT. Kütüphane kullanmadan: token'ı üçe böldüm, Apple'ın public key'lerini çektim, `kid`'e göre doğru anahtarı buldum, WebCrypto ile RSASSA-PKCS1-v1_5 imzasını doğruladım, sonra issuer/audience/expiry kontrol ettim. Google tarafında Google'ın tokeninfo endpoint'ine güvendim ama yine iss/aud/exp'i elle kontrol ettim. "İmzayı doğrulamak" cümlesini artık ezberden değil, byte'ından biliyorum.

4. **Kendi oturum JWT'mi imzaladım.** Kullanıcı doğrulandıktan sonra 90 günlük kendi HS256 oturum token'ımı ürettim — base64url encode'unu, HMAC-SHA256 imzasını elle yazdım (`stringToB64url`, `hmac`, `requireSession`). Her istekte token'ı çözüp imzayı yeniden hesaplayıp karşılaştırıyorum, süresi geçmişse reddediyorum. Bir framework'ün üç satırda sakladığı şeyi otuz satırda açtım — ve şimdi ne olduğunu biliyorum.

5. **Dürüst downfall.** Bu backend şu an **uykuda.** Kod canlı, D1 şeması hazır, worker.js'de auth route'ları duruyor — ama uygulamada henüz giriş ekranı yok. Ship-check bunu açıkça yazdı: "dormant auth endpoints". Bunu saklamıyorum çünkü öğrenme projesinin doğası bu: backend'i sistemi anlamak için yazdım, ürün henüz oraya gelmedi. Ve bir uyarı da öğrendim: giriş ekranını uygulamaya koyduğum gün, Apple kuralı gereği **uygulama-içi hesap silme** zorunlu olacak. Yani bir sonraki backend işim baştan belli.

6. **Ders.** Auth'u kendim yazmak bana bir kütüphanenin veremeyeceğini verdi: sistemin nerede kırılabileceğini gördüm. `aud` kontrolünü atlarsam başka uygulamanın token'ı benimkine girer. `exp`'i atlarsam token hiç ölmez. Bunları "biri halletmiş" diye geçmek yerine tek tek yazınca, mimari artık soyut değil — benim kararlarım.

---

## Essay 3 — "Yavaş bir API'yi uygulamanın içinden düzelttim: ChartCache"

1. **Problem: dışarısı yavaş, suç bende değil ama sorumluluk benim.** Astroloji chart'larını freeastrologyapi'den çekiyordum. Bazen upstream saniyelerce takılıyordu, bazen düşüyordu. Kullanıcı için fark yok: benim uygulamam donuyor gibi görünüyor. Backend'i değiştiremiyordum (dış servis), ama **istemci mimarisini** değiştirebilirdim.

2. **Karar: cache'i uygulama tarafında kur.** ChartCache yazdım. Üç ilke: (a) **request coalescing** — aynı chart aynı anda iki kez istenirse iki kez ağa çıkma, ilk isteğe iliştir. (b) **akıllı TTL** — "şimdi" chart'ı 10 dakika, natal (doğum) chart'ı ise sonsuza kadar cache'le, çünkü doğum haritan değişmez. (c) **stale-on-failure** — upstream düşerse hata gösterme, elindeki bayat veriyi ver. Üstüne 15 saniye timeout.

3. **Neden önemli.** Bu, mimarinin klasik bir dersi: **kontrol edemediğin bir bağımlılığın etrafına tampon koyarsın.** Dış API'nin yavaşlığını benim kullanıcım çekmemeli. Coalescing tek başına, aynı ekranda üç widget aynı chart'ı isterse üç isteği bire indiriyor. "Stale serve" kararı ise bir felsefe: eski doğru veri, taze hatadan iyidir.

4. **Aynı mantığı günlük okuma kartına da uyguladım.** Ana ekranda günlük bir "gökyüzü okuması" var. Her açılışta yeni bir Claude çağrısı yapmak hem yavaş hem pahalı olurdu. Karar: kullanıcı başına günde bir kez, dile göre cache'lenmiş tek çağrı. Not düştüm: ölçek büyürse bunu Worker'da KV-cache'li bir endpoint'e taşımak lazım — "iyi bir öğrenme egzersizi" diye kenara yazdım, çünkü bu projenin amacı zaten o.

5. **Ders.** Bir sistem sadece kendi yazdığın kod değildir; kontrol edemediğin dış servisler de sistemin parçasıdır. İyi mimari, o servisler yavaşladığında veya öldüğünde uygulamanın nasıl davranacağına önceden karar vermektir. ChartCache'ten sonra "backend öğreniyorum" cümlem genişledi: backend, sunucu kurmak değil, **hataya ve gecikmeye karşı bir plan** kurmaktır.

---

## Essay 4 — "Piksel fontlar, silinen özellikler ve KVKK: bir öğrenme projesi de yalan söyleyemez"

1. **Tasarımda ileri-geri gittim, saklamıyorum.** Uygulama üç estetikten geçti. Önce SF Symbols ve yuvarlak dikdörtgenler. Sonra "piksel sanat" dönemi: bütün SF sembollerini, daireleri piksel bileşenlerle değiştirdim, Pixelify Sans fontu koydum, kod-çizimli piksel yıldızlar yaptım. Okunabilirlik için gövde metnini de Pixelify'a çektim. Sonra bir gün karar verdim: **piksel font okunmuyor.** Hepsini geri aldım — başlıklar Fraunces SemiBold, gövde Inter, tam Türkçe glif setiyle statik instance'lar. Üç estetik, iki pivot. Doğru tasarım, denemeden bilinmiyor.

2. **Bir özelliği doğduğu gece sildim.** Okumaları paylaşmak için altın çerçeveli, yıldız alanlı bir "paylaşım kartı" yaptım — döner mistik yükleme metinleri, tam paket. Damla altın süslemeyi reddetti. Özelliği aynı gece sildim. Not düştüm: somut bir referans olmadan geri ekleme. Bir şeyi yapabilmek, yapılması gerektiği anlamına gelmiyor.

3. **Asıl ders KVKK'da geldi.** Onboarding ekranı kullanıcıya söz veriyordu: "Verilerin cihazında kalır. İstediğin zaman sil." Ship-check bunu yakaladı: **o buton hiç yoktu.** `UserProfile.reset()` kodda vardı ama hiçbir ekrandan çağrılmıyordu. Yani uygulamam reklamı yaptığı hakkı vermiyordu — hem CRUD kuralını hem de KVKK'nın silme hakkını çiğniyordu. Aynı oturumda düzelttim: Ayarlar'a "Doğum bilgilerini düzenle" ve "Verilerimi sil" (profil + okuma geçmişi + cache temizleyen, onaylı) koydum.

4. **Gizlilik politikası ölüydü.** Repo org taşınınca politika ve şartlar URL'leri 404 vermeye başlamıştı — uygulama içindeki linkler ölü sayfalara gidiyordu. App Store çalışan bir gizlilik politikası URL'i şart koşuyor, KVKK de. GitHub Pages'i açtım, linkleri düzelttim, politikanın içeriğini de gerçeğe uydurdum (doğum verisi chart hesabı için gönderiliyor, isim toplanıyor) ve KVKK/GDPR hakları bölümü ekledim. Privacy manifest'i de eksikti — konum yanında isim ve kullanıcı sorularını da beyan ettim.

5. **Ders.** Bir öğrenme projesi de gerçek kullanıcıya çıkıyorsa, "sadece öğreniyorum" bir mazeret değil. Onboarding'de "sil" yazıp silme butonu koymamak yalandır. Mimari öğrenmek, sadece token imzalamak değil; kullanıcıya verdiğin sözü kodda tutmaktır. moonlight bana backend'i öğretirken, aynı zamanda **dürüstlüğün de bir mühendislik gereksinimi** olduğunu öğretti.
