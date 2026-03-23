import SwiftUI

struct CreditBadge: View {
    @StateObject private var creditManager = CreditManager.shared
    let onTap: () -> Void

    private let titleFont = "PressStart2P-Regular"
    private let accent = Color(hex: "#FFE566")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                // Pixel coin
                ZStack {
                    Rectangle()
                        .fill(accent)
                        .frame(width: 14, height: 14)
                    Rectangle()
                        .fill(Color(hex: "#D4A017"))
                        .frame(width: 10, height: 10)
                    Rectangle()
                        .fill(accent)
                        .frame(width: 6, height: 6)
                }

                Text("\(creditManager.totalCredits)")
                    .font(.custom(titleFont, size: 10))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color(hex: "#1a1a4a"))
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "#2a2a6e"), lineWidth: 2)
                    )
            )
        }
    }
}
