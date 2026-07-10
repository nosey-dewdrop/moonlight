import SwiftUI

/// Rotating mystic phrases for the AI wait (5-10s). A static spinner makes the
/// wait feel long; changing copy every ~2.4s keeps it alive.
struct MysticLoadingText: View {
    @State private var index = 0

    private var phrases: [String] {
        [
            L("Yıldızlar hizalanıyor...", "The stars are aligning..."),
            L("Gökyüzü haritası çiziliyor...", "Drawing the sky chart..."),
            L("Gezegenler fısıldıyor...", "The planets are whispering..."),
            L("Ay ışığı toplanıyor...", "Gathering moonlight..."),
            L("Kadim semboller okunuyor...", "Reading the old symbols..."),
        ]
    }

    var body: some View {
        HStack(spacing: 8) {
            PixelLoading(color: Theme.accent)
            Text(phrases[index % phrases.count])
                .font(.custom(Theme.bodyFont, size: 14))
                .foregroundColor(.white.opacity(0.5))
                .id(index)
                .transition(.opacity)
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2.4))
                withAnimation(.easeInOut(duration: 0.4)) { index += 1 }
            }
        }
    }
}
