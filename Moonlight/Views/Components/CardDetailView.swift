import SwiftUI

struct CardDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let card: TarotCard

    private var turkishName: String {
        var name = card.name
        // Suit translations
        name = name.replacingOccurrences(of: "Pentacles", with: "Tılsımlar")
        name = name.replacingOccurrences(of: "Cups", with: "Kupalar")
        name = name.replacingOccurrences(of: "Wands", with: "Asalar")
        name = name.replacingOccurrences(of: "Swords", with: "Kılıçlar")
        // Court cards
        name = name.replacingOccurrences(of: "Page of", with: "Uşak of")
        name = name.replacingOccurrences(of: "Knight of", with: "Şövalye of")
        name = name.replacingOccurrences(of: "Queen of", with: "Kraliçe of")
        name = name.replacingOccurrences(of: "King of", with: "Kral of")
        // Number cards
        name = name.replacingOccurrences(of: "Ace of", with: "As of")
        name = name.replacingOccurrences(of: "Two of", with: "İki of")
        name = name.replacingOccurrences(of: "Three of", with: "Üç of")
        name = name.replacingOccurrences(of: "Four of", with: "Dört of")
        name = name.replacingOccurrences(of: "Five of", with: "Beş of")
        name = name.replacingOccurrences(of: "Six of", with: "Altı of")
        name = name.replacingOccurrences(of: "Seven of", with: "Yedi of")
        name = name.replacingOccurrences(of: "Eight of", with: "Sekiz of")
        name = name.replacingOccurrences(of: "Nine of", with: "Dokuz of")
        name = name.replacingOccurrences(of: "Ten of", with: "On of")
        // Fix "of" to proper Turkish
        name = name.replacingOccurrences(of: " of ", with: " ")
        // Major arcana
        name = name.replacingOccurrences(of: "The Fool", with: "Deli")
        name = name.replacingOccurrences(of: "The Magician", with: "Sihirbaz")
        name = name.replacingOccurrences(of: "The High Priestess", with: "Başrahibe")
        name = name.replacingOccurrences(of: "The Empress", with: "İmparatoriçe")
        name = name.replacingOccurrences(of: "The Emperor", with: "İmparator")
        name = name.replacingOccurrences(of: "The Hierophant", with: "Aziz")
        name = name.replacingOccurrences(of: "The Lovers", with: "Aşıklar")
        name = name.replacingOccurrences(of: "The Chariot", with: "Savaş Arabası")
        name = name.replacingOccurrences(of: "Strength", with: "Güç")
        name = name.replacingOccurrences(of: "The Hermit", with: "Münzevi")
        name = name.replacingOccurrences(of: "Wheel of Fortune", with: "Kader Çarkı")
        name = name.replacingOccurrences(of: "Justice", with: "Adalet")
        name = name.replacingOccurrences(of: "The Hanged Man", with: "Asılan Adam")
        name = name.replacingOccurrences(of: "Death", with: "Ölüm")
        name = name.replacingOccurrences(of: "Temperance", with: "Denge")
        name = name.replacingOccurrences(of: "The Devil", with: "Şeytan")
        name = name.replacingOccurrences(of: "The Tower", with: "Kule")
        name = name.replacingOccurrences(of: "The Star", with: "Yıldız")
        name = name.replacingOccurrences(of: "The Moon", with: "Ay")
        name = name.replacingOccurrences(of: "The Sun", with: "Güneş")
        name = name.replacingOccurrences(of: "Judgement", with: "Mahkeme")
        name = name.replacingOccurrences(of: "The World", with: "Dünya")
        return name
    }

    private var cardLore: String {
        if card.arcana == .major {
            return majorArcanaLore[card.name] ?? card.meaning
        }
        return minorArcanaLore()
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Header
                    HStack {
                        Button(action: { dismiss() }) {
                            Text("X")
                                .font(.custom(Theme.titleFont, size: 10))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(8)
                        }
                        Spacer()
                    }
                    .padding(.top, 50)

                    // Card name
                    Text(turkishName)
                        .font(.custom(Theme.titleFont, size: 14))
                        .foregroundColor(Theme.accent)
                        .shadow(color: Theme.accent.opacity(0.5), radius: 4)
                        .multilineTextAlignment(.center)

                    Text(card.name)
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.3))

                    // Keywords
                    HStack(spacing: 8) {
                        ForEach(card.keywords, id: \.self) { keyword in
                            Text(keyword)
                                .font(.custom(Theme.bodyFont, size: 13))
                                .foregroundColor(Theme.accent.opacity(0.8))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }

                    // Meaning
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Anlam")
                            .font(.custom(Theme.titleFont, size: 10))
                            .foregroundColor(.white.opacity(0.5))

                        Text(card.meaning)
                            .font(.custom(Theme.bodyFont, size: 15))
                            .foregroundColor(.white.opacity(0.8))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.bg.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )

                    // Lore / History
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tarihçe")
                            .font(.custom(Theme.titleFont, size: 10))
                            .foregroundColor(.white.opacity(0.5))

                        Text(cardLore)
                            .font(.custom(Theme.bodyFont, size: 15))
                            .foregroundColor(.white.opacity(0.7))
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.bg.opacity(0.85))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )

                    // Arcana & Suit info
                    if let suit = card.suit {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Element")
                                .font(.custom(Theme.titleFont, size: 10))
                                .foregroundColor(.white.opacity(0.5))

                            Text(suitDescription(suit))
                                .font(.custom(Theme.bodyFont, size: 15))
                                .foregroundColor(.white.opacity(0.7))
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.bg.opacity(0.85))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - Suit Descriptions

    private func suitDescription(_ suit: Suit) -> String {
        switch suit {
        case .wands:
            return "Asalar ateş elementini temsil eder. Tutku, yaratıcılık, irade gücü ve ilham ile ilgilidir. Ateş enerjisi harekete geçirir ve motive eder."
        case .cups:
            return "Kupalar su elementini temsil eder. Duygular, ilişkiler, sezgi ve ruhani bağlantılarla ilgilidir. Su enerjisi hissetmeyi ve empatiyi güçlendirir."
        case .swords:
            return "Kılıçlar hava elementini temsil eder. Düşünce, iletişim, mantık ve zihinsel netlikle ilgilidir. Hava enerjisi analiz ve karar vermeyi keskinleştirir."
        case .pentacles:
            return "Tılsımlar toprak elementini temsil eder. Maddi dünya, para, sağlık ve somut sonuçlarla ilgilidir. Toprak enerjisi sabır ve istikrar getirir."
        }
    }

    // MARK: - Major Arcana Lore

    private let majorArcanaLore: [String: String] = [
        "The Fool": "Deli kartı tarot destesinin 0 numaralı kartıdır ve tüm yolculuğun başlangıcını simgeler. Ortaçağ Avrupa'sında saray soytarısından esinlenmiştir. Bilinmeyene adım atmayı, saf güveni ve yeni başlangıçları temsil eder.",
        "The Magician": "Sihirbaz, dört elementin ustasıdır. Masasında asa, kupa, kılıç ve tılsım bulunur. İradenin gücünü ve 'yukarıda ne varsa aşağıda da o vardır' ilkesini simgeler. Hermes Trismegistus'tan ilham alır.",
        "The High Priestess": "Başrahibe, bilinçaltının ve gizemlerin koruyucusudur. İki sütun arasında oturur — biri siyah, biri beyaz — zıtlıkların dengesini gösterir. Sezgisel bilgeliği ve iç sesin gücünü temsil eder.",
        "The Empress": "İmparatoriçe, bereketin ve yaratıcılığın kartıdır. Doğa ana ile özdeşleşir. Venüs gezegeniyle bağlantılıdır. Besleyici enerji, bolluk ve hayatın çiçek açmasını simgeler.",
        "The Emperor": "İmparator, düzen ve otoritenin kartıdır. Taş tahtında oturur, elinde asa ve küre tutar. Mars gezegeniyle bağlantılıdır. Yapı, disiplin ve koruyucu güç anlamına gelir.",
        "The Hierophant": "Aziz, ruhani öğretmen ve geleneklerin taşıyıcısıdır. Papa figüründen esinlenmiştir. Manevi rehberlik, köklü bilgi ve toplumsal değerleri temsil eder.",
        "The Lovers": "Aşıklar kartı sadece romantik aşkı değil, hayattaki önemli seçimleri de simgeler. Adem ile Havva'dan esinlenmiştir. İkizler burcuyla bağlantılıdır. Değerler uyumu ve bilinçli tercih anlamına gelir.",
        "The Chariot": "Savaş Arabası, irade gücüyle engelleri aşmayı simgeler. İki zıt gücü (siyah ve beyaz sfenks) kontrol eden bir savaşçı tasvir edilir. Yengeç burcuyla bağlantılıdır. Kararlılık ve zafer anlamına gelir.",
        "Strength": "Güç kartı, fiziksel güçten çok içsel gücü temsil eder. Bir kadın nazikçe bir aslanın ağzını kapatır. Aslan burcuyla bağlantılıdır. Sabır, şefkat ve korkularla yüzleşme cesareti anlamına gelir.",
        "The Hermit": "Münzevi, iç yolculuğun ve bilgelik arayışının kartıdır. Elinde fener tutan yaşlı bir bilge tasvir edilir. Başak burcuyla bağlantılıdır. Yalnızlıkta bulunan cevapları simgeler.",
        "Wheel of Fortune": "Kader Çarkı, hayatın döngüselliğini gösterir. Ortaçağ 'Rota Fortunae' konseptinden gelir. Jüpiter gezegeniyle bağlantılıdır. Şans, kader ve değişimin kaçınılmazlığını temsil eder.",
        "Justice": "Adalet kartı, sebep-sonuç ilişkisini ve hakikati simgeler. Bir elinde kılıç, diğerinde terazi tutar. Terazi burcuyla bağlantılıdır. Dürüstlük, sorumluluk ve karmanın dengelenmesi anlamına gelir.",
        "The Hanged Man": "Asılan Adam, gönüllü fedakarlığı ve bakış açısı değişimini simgeler. İskandinav mitolojisinde Odin'in bilgelik için kendini ağaca asmasından esinlenmiştir. Teslimiyetin getirdiği aydınlanmayı temsil eder.",
        "Death": "Ölüm kartı fiziksel ölümü değil, köklü dönüşümü simgeler. Bir dönemin kapanıp yenisinin başlamasıdır. Akrep burcuyla bağlantılıdır. Bırakma, yenilenme ve kaçınılmaz değişim anlamına gelir.",
        "Temperance": "Denge kartı, ölçülülüğü ve uyumu simgeler. Bir melek iki kap arasında su aktarır — zıtlıkların harmanlanması. Yay burcuyla bağlantılıdır. Sabır, denge ve orta yolu bulma anlamına gelir.",
        "The Devil": "Şeytan kartı, bağımlılıkları ve kendi kendine kurduğumuz zincirleri gösterir. Baphomet figüründen esinlenmiştir. Oğlak burcuyla bağlantılıdır. Gölge benlik, takıntılar ve özgürleşme ihtiyacını temsil eder.",
        "The Tower": "Kule, ani yıkımı ve vahiyleri simgeler. Babil Kulesi'nden esinlenmiştir. Mars gezegeniyle bağlantılıdır. Sahte yapıların çöküşünü ve bu yıkımdan doğan özgürlüğü temsil eder.",
        "The Star": "Yıldız, umut ve iyileşmenin kartıdır. Kule'nin yıkımından sonra gelen huzuru temsil eder. Kova burcuyla bağlantılıdır. İlham, inanç ve evrenle uyum anlamına gelir.",
        "The Moon": "Ay kartı, bilinçaltının derinliklerini ve yanılsamaları simgeler. Ay ışığında her şey olduğundan farklı görünür. Balık burcuyla bağlantılıdır. Sezgi, korkular ve gizli gerçekler anlamına gelir.",
        "The Sun": "Güneş, saf neşe ve başarının kartıdır. Tarot destesinin en olumlu kartlarından biridir. Çocuksu mutluluk, canlılık ve her şeyin aydınlanması anlamına gelir.",
        "Judgement": "Mahkeme kartı, uyanışı ve hesap vermeyi simgeler. Kıyamet günü tasvirinden esinlenmiştir. Plüton gezegeniyle bağlantılıdır. İç çağrıyı duyma, geçmişle yüzleşme ve yeniden doğuş anlamına gelir.",
        "The World": "Dünya, tamamlanma ve bütünlüğün kartıdır. Tarot yolculuğunun son durağıdır. Satürn gezegeniyle bağlantılıdır. Başarı, entegrasyon ve bir döngünün zaferle kapanması anlamına gelir.",
    ]

    // MARK: - Minor Arcana Lore

    private func minorArcanaLore() -> String {
        guard let suit = card.suit else { return card.meaning }

        let suitLore: [Suit: String] = [
            .wands: "Asalar serisi, ateş elementinin enerjisini taşır. İlham, yaratıcılık ve eyleme geçme gücünü anlatır.",
            .cups: "Kupalar serisi, su elementinin akışkanlığını taşır. Duygusal dünya, ilişkiler ve ruhani deneyimleri anlatır.",
            .swords: "Kılıçlar serisi, hava elementinin keskinliğini taşır. Zihinsel süreçler, çatışmalar ve gerçeğin keşfini anlatır.",
            .pentacles: "Tılsımlar serisi, toprak elementinin sağlamlığını taşır. Maddi dünya, kariyer ve somut başarıları anlatır.",
        ]

        return (suitLore[suit] ?? "") + " " + card.meaning
    }
}
