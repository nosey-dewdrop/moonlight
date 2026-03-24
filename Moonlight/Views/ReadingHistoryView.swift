import SwiftUI

struct ReadingHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Regular"
    private let bodyBoldFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")
    private let bg = Color(hex: "#0b0b2e")

    private var records: [ReadingRecord] {
        ReadingHistory.shared.records
    }

    var body: some View {
        ZStack {
            bg.ignoresSafeArea()

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

                if records.isEmpty {
                    Spacer()
                    Text("No readings yet")
                        .font(.custom(bodyFont, size: 12))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Your questions will appear here")
                        .font(.custom(bodyFont, size: 10))
                        .foregroundColor(.white.opacity(0.2))
                    Spacer()
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 8) {
                            ForEach(records) { record in
                                historyRow(record)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 40)
                    }
                }
            }
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
                Text(record.question)
                    .font(.custom(bodyFont, size: 11))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(2)

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
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
