import SwiftUI

struct CreditBadge: View {
    @ObservedObject private var creditManager = CreditManager.shared
    let onTap: () -> Void

    private let titleFont = "PressStart2P-Regular"
    private let bodyFont = "Silkscreen-Bold"
    private let accent = Color(hex: "#FFE566")

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Round pixel coin
                ZStack {
                    // Outer circle (3x3 pixel cross = circle illusion)
                    VStack(spacing: 0) {
                        Rectangle().fill(accent).frame(width: 10, height: 2)
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                        Rectangle().fill(accent).frame(width: 14, height: 2)
                        Rectangle().fill(accent).frame(width: 10, height: 2)
                    }
                    // Inner dark
                    VStack(spacing: 0) {
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 6, height: 2)
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 10, height: 2)
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 10, height: 2)
                        Rectangle().fill(Color(hex: "#D4A017")).frame(width: 6, height: 2)
                    }
                    // + sign
                    Rectangle().fill(accent).frame(width: 6, height: 2)
                    Rectangle().fill(accent).frame(width: 2, height: 6)
                }
                .frame(width: 14, height: 14)

                Text("\(creditManager.totalCredits)")
                    .font(.custom(titleFont, size: 10))
                    .foregroundColor(.white)

                // + button
                Text("+")
                    .font(.custom(titleFont, size: 10))
                    .foregroundColor(accent)
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
        .accessibilityLabel("\(creditManager.totalCredits) credits")
    }
}
