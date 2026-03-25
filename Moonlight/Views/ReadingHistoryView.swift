import SwiftUI

struct ReadingHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var records: [ReadingRecord] = []

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")
    private let moonService = MoonService()

    private var sortedRecords: [ReadingRecord] {
        // Favorites first, then by date
        records.sorted { a, b in
            if a.isFavorite != b.isFavorite { return a.isFavorite }
            return a.date > b.date
        }
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

            if let moonData = moonService.calculateMoonPhase(date: Date()) as MoonData? {
                MoonSceneView(moonData: moonData, showMoon: false)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            VStack(spacing: 16) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Text("X")
                            .font(.custom(titleFont, size: 10))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                    }
                    Spacer()
                    Text("History")
                        .font(.custom(titleFont, size: 14))
                        .foregroundColor(accent)
                    Spacer()
                    Color.clear.frame(width: 28)
                }
                .padding(.top, 60)
                .padding(.horizontal, 16)

                if sortedRecords.isEmpty {
                    Spacer()
                    Text("No readings yet")
                        .font(.custom(bodyFont, size: 12))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Your questions will appear here")
                        .font(.custom(bodyFont, size: 10))
                        .foregroundColor(.white.opacity(0.2))
                    Spacer()
                } else {
                    List {
                        ForEach(sortedRecords) { record in
                            historyRow(record)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        ReadingHistory.shared.delete(id: record.id)
                                        records = ReadingHistory.shared.records
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        ReadingHistory.shared.toggleFavorite(id: record.id)
                                        records = ReadingHistory.shared.records
                                    } label: {
                                        Image(systemName: record.isFavorite ? "star.slash" : "star.fill")
                                    }
                                    .tint(accent)
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            records = ReadingHistory.shared.records
        }
    }

    private func historyRow(_ record: ReadingRecord) -> some View {
        HStack(spacing: 10) {
            Text(record.type == .tarot ? "T" : "H")
                .font(.custom(titleFont, size: 9))
                .foregroundColor(record.type == .tarot ? accent : Color(hex: "#A78BFA"))
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 2)
                        .fill((record.type == .tarot ? accent : Color(hex: "#A78BFA")).opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if record.isFavorite {
                        Text("*")
                            .font(.custom(titleFont, size: 8))
                            .foregroundColor(accent)
                    }
                    Text(record.question)
                        .font(.custom(bodyFont, size: 11))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }

                Text(formatDate(record.date))
                    .font(.custom(bodyFont, size: 9))
                    .foregroundColor(.white.opacity(0.3))
            }

            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(bg.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(record.isFavorite ? accent.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM, HH:mm"
        return formatter.string(from: date)
    }
}

#Preview {
    ReadingHistoryView()
}
