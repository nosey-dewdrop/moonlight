import SwiftUI

struct ReadingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var loc = LocalizationManager.shared
    @State private var records: [ReadingRecord] = []
    @State private var selectedRecord: ReadingRecord?
    @State private var sortedRecords: [ReadingRecord] = []
    @State private var moonData: MoonData?

    private let moonService = MoonService()

    private func updateSortedRecords() {
        sortedRecords = records.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            return a.date > b.date
        }
    }

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()

            if let moonData = moonData {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("X")
                            .font(.custom(Theme.titleFont, size: 11))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                    }
                    Spacer()
                    Text(L("Geçmiş", "History"))
                        .font(.custom(Theme.titleFont, size: 24))
                        .foregroundColor(Theme.accent)
                    Spacer()
                    Color.clear.frame(width: 28)
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)

                if sortedRecords.isEmpty {
                    Spacer()
                    Text(L("Henüz okuma yok", "No readings yet"))
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.3))
                    Text(L("Soruların burada görünecek", "Your questions will appear here"))
                        .font(.custom(Theme.bodyFont, size: 14))
                        .foregroundColor(.white.opacity(0.2))
                    Spacer()
                } else {
                    List {
                        ForEach(sortedRecords) { record in
                            historyRow(record)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if record.reading != nil { selectedRecord = record }
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        ReadingHistory.shared.delete(id: record.id)
                                        records = ReadingHistory.shared.records
                                        updateSortedRecords()
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        ReadingHistory.shared.toggleFavorite(id: record.id)
                                        records = ReadingHistory.shared.records
                                        updateSortedRecords()
                                    } label: {
                                        Image(systemName: record.isFavorite ? "star.slash" : "star.fill")
                                    }
                                    .tint(Theme.accent)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            moonData = moonService.calculateMoonPhase(date: Date())
            records = ReadingHistory.shared.records
            updateSortedRecords()
        }
        .sheet(item: $selectedRecord) { record in
            ReadingDetailSheet(record: record)
        }
    }

    private func historyRow(_ record: ReadingRecord) -> some View {
        HStack(spacing: 10) {
            Text(record.type == .tarot ? "T" : "H")
                .font(.custom(Theme.titleFont, size: 11))
                .foregroundColor(record.type == .tarot ? Theme.accent : Theme.purpleAccent)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill((record.type == .tarot ? Theme.accent : Theme.purpleAccent).opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if record.isFavorite {
                        Text("*")
                            .font(.custom(Theme.titleFont, size: 16))
                            .foregroundColor(Theme.accent)
                    }
                    Text(record.question)
                        .font(.custom(Theme.bodyFont, size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                Text(formatDate(record.date))
                    .font(.custom(Theme.bodyFont, size: 13))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(Theme.bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(record.isFavorite ? Theme.accent.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func formatDate(_ date: Date) -> String {
        Theme.historyDateFormatter.string(from: date)
    }
}

/// Full saved reading — history rows were dead records before this; now a tap
/// reopens the whole text, shareable again.
private struct ReadingDetailSheet: View {
    let record: ReadingRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(record.question)
                        .font(.custom(Theme.titleFont, size: 16))
                        .foregroundColor(Theme.accent)
                        .padding(.top, 30)

                    Text(Theme.historyDateFormatter.string(from: record.date))
                        .font(.custom(Theme.bodyFont, size: 12))
                        .foregroundColor(.white.opacity(0.35))

                    if let reading = record.reading {
                        Text(reading)
                            .font(.custom(Theme.bodyFont, size: 15))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(5)

                        ShareReadingButton(question: record.question,
                                           reading: reading,
                                           moonPhaseName: MoonService().calculateMoonPhase(date: record.date).phase.displayName)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 8)
                    }
                }
                .padding(20)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button(action: { dismiss() }) {
                Text("X")
                    .font(.custom(Theme.titleFont, size: 12))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(14)
            }
            .accessibilityLabel("Close")
        }
    }
}

#Preview {
    ReadingHistoryView()
}
