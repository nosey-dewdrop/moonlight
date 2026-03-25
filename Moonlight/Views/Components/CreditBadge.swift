import SwiftUI

struct CreditBadge: View {
    @ObservedObject private var creditManager = CreditManager.shared
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                // Round pixel coin
                ZStack {
                    VStack(spacing: 0) {
                        Rectangle().fill(Theme.accent).frame(width: 10, height: 2)
                        Rectangle().fill(Theme.accent).frame(width: 14, height: 2)
                        Rectangle().fill(Theme.accent).frame(width: 14, height: 2)
                        Rectangle().fill(Theme.accent).frame(width: 14, height: 2)
                        Rectangle().fill(Theme.accent).frame(width: 14, height: 2)
                        Rectangle().fill(Theme.accent).frame(width: 14, height: 2)
                        Rectangle().fill(Theme.accent).frame(width: 10, height: 2)
                    }
                    VStack(spacing: 0) {
                        Rectangle().fill(Theme.coinInner).frame(width: 6, height: 2)
                        Rectangle().fill(Theme.coinInner).frame(width: 10, height: 2)
                        Rectangle().fill(Theme.coinInner).frame(width: 10, height: 2)
                        Rectangle().fill(Theme.coinInner).frame(width: 6, height: 2)
                    }
                    Rectangle().fill(Theme.accent).frame(width: 6, height: 2)
                    Rectangle().fill(Theme.accent).frame(width: 2, height: 6)
                }
                .frame(width: 14, height: 14)

                Text("\(creditManager.totalCredits)")
                    .font(.custom(Theme.titleFont, size: 10))
                    .foregroundColor(.white)

                Text("+")
                    .font(.custom(Theme.titleFont, size: 10))
                    .foregroundColor(Theme.accent)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Theme.badgeBg)
                    .overlay(
                        Capsule()
                            .stroke(Theme.badgeBorder, lineWidth: 2)
                    )
            )
        }
        .accessibilityLabel("\(creditManager.totalCredits) credits")
    }
}
