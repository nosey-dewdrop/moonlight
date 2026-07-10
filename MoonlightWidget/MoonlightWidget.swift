import WidgetKit
import SwiftUI

// The widget runs in its own process, so it cannot see the app's in-app
// language override or call app services. Everything here is self-contained:
// the moon math is the same Julian-day formula MoonService uses, and language
// follows the system locale.

// MARK: - Moon math

struct MoonSnapshot {
    let date: Date
    let illumination: Int
    let isWaxing: Bool
    let phaseIndex: Int   // 0 new … 4 full … 7 waning crescent

    static func compute(for date: Date) -> MoonSnapshot {
        let calendar = Calendar.current
        let c = calendar.dateComponents([.year, .month, .day, .hour], from: date)
        var y = c.year ?? 2026
        var m = c.month ?? 1
        let day = c.day ?? 1
        let hour = c.hour ?? 0
        if m <= 2 { y -= 1; m += 12 }
        let a = y / 100
        let b = 2 - a + a / 4
        let e = Int(365.25 * Double(y + 4716))
        let f = Int(30.6001 * Double(m + 1))
        let jd = Double(b + day + e + f) + Double(hour) / 24.0 - 1524.5

        let synodicMonth = 29.53058868
        let age = (jd - 2451550.1).truncatingRemainder(dividingBy: synodicMonth)
        let normalizedAge = age < 0 ? age + synodicMonth : age

        let illumination = (1.0 - cos(normalizedAge / synodicMonth * 2.0 * .pi)) / 2.0 * 100.0
        let isWaxing = normalizedAge < synodicMonth / 2.0

        let pct = illumination / 100.0
        let index: Int
        if pct < 0.02 { index = 0 }
        else if pct > 0.98 { index = 4 }
        else if isWaxing {
            if pct < 0.48 { index = 1 } else if pct < 0.52 { index = 2 } else { index = 3 }
        } else {
            if pct < 0.48 { index = 7 } else if pct < 0.52 { index = 6 } else { index = 5 }
        }

        return MoonSnapshot(date: date, illumination: Int(illumination.rounded()),
                            isWaxing: isWaxing, phaseIndex: index)
    }

    var symbolName: String {
        ["moonphase.new.moon", "moonphase.waxing.crescent", "moonphase.first.quarter",
         "moonphase.waxing.gibbous", "moonphase.full.moon", "moonphase.waning.gibbous",
         "moonphase.last.quarter", "moonphase.waning.crescent"][phaseIndex]
    }

    var name: String {
        let tr = Locale.current.language.languageCode?.identifier == "tr"
        let names = tr
            ? ["Yeni Ay", "İlk Hilal", "İlk Dördün", "Şişkin Ay", "Dolunay", "Küçülen Ay", "Son Dördün", "Son Hilal"]
            : ["New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous", "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent"]
        return names[phaseIndex]
    }
}

// MARK: - Timeline

struct MoonEntry: TimelineEntry {
    let date: Date
    let moon: MoonSnapshot
}

struct MoonProvider: TimelineProvider {
    func placeholder(in context: Context) -> MoonEntry {
        MoonEntry(date: .now, moon: .compute(for: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (MoonEntry) -> Void) {
        completion(MoonEntry(date: .now, moon: .compute(for: .now)))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MoonEntry>) -> Void) {
        // One entry every 6 hours for 4 days — illumination creeps ~3% per entry,
        // then WidgetKit asks again.
        let calendar = Calendar.current
        let now = Date()
        var entries: [MoonEntry] = []
        for step in 0..<16 {
            if let date = calendar.date(byAdding: .hour, value: step * 6, to: now) {
                entries.append(MoonEntry(date: date, moon: .compute(for: date)))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Views

private let navy = Color(red: 11 / 255, green: 11 / 255, blue: 46 / 255)
private let gold = Color(red: 1.0, green: 229 / 255, blue: 102 / 255)
private let faintText = Color(red: 184 / 255, green: 176 / 255, blue: 216 / 255)

struct MoonWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MoonEntry

    var body: some View {
        switch family {
        case .accessoryCircular:
            Image(systemName: entry.moon.symbolName)
                .font(.system(size: 40))
                .widgetAccentable()
                .containerBackground(.clear, for: .widget)
        case .accessoryInline:
            Text("\(entry.moon.name) %\(entry.moon.illumination)")
                .containerBackground(.clear, for: .widget)
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: entry.moon.symbolName)
                    .font(.system(size: 28))
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 1) {
                    Text(entry.moon.name)
                        .font(.headline)
                    Text("%\(entry.moon.illumination)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            .containerBackground(.clear, for: .widget)
        default:
            VStack(spacing: 6) {
                Image(systemName: entry.moon.symbolName)
                    .font(.system(size: 52))
                    .foregroundStyle(gold)
                Text(entry.moon.name)
                    .font(.system(size: 15, weight: .semibold, design: .serif))
                    .foregroundStyle(.white)
                Text("%\(entry.moon.illumination)")
                    .font(.system(size: 12))
                    .foregroundStyle(faintText)
            }
            .containerBackground(navy, for: .widget)
        }
    }
}

// MARK: - Widget

struct MoonlightWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MoonlightMoonPhase", provider: MoonProvider()) { entry in
            MoonWidgetView(entry: entry)
        }
        .configurationDisplayName(Locale.current.language.languageCode?.identifier == "tr" ? "Ay Fazı" : "Moon Phase")
        .description(Locale.current.language.languageCode?.identifier == "tr"
                     ? "Bugünün ayı ve aydınlanma oranı."
                     : "Today's moon and its illumination.")
        .supportedFamilies([.systemSmall, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@main
struct MoonlightWidgetBundle: WidgetBundle {
    var body: some Widget {
        MoonlightWidget()
    }
}
