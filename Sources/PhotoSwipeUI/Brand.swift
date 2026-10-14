import SwiftUI

/// The brand mark: three photo prints. `spread` 0 = stacked, 1 = fanned out.
struct CardFan: View {
    var spread: CGFloat = 1
    var size: CGFloat = 120

    var body: some View {
        ZStack {
            print(Color(white: 0.45))
                .rotationEffect(.degrees(-14 * spread), anchor: .bottom)
                .offset(x: -size * 0.22 * spread)
            print(Color(white: 0.72))
                .rotationEffect(.degrees(14 * spread), anchor: .bottom)
                .offset(x: size * 0.22 * spread)
            print(.white)
        }
        .frame(width: size * 1.6, height: size * 1.15)
    }

    private func print(_ color: Color) -> some View {
        RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
            .fill(color)
            .frame(width: size * 0.76, height: size)
            .shadow(color: .black.opacity(0.5), radius: size * 0.08, y: size * 0.05)
    }
}

/// A thin progress line. Used instead of rings and tiles.
struct ProgressLine: View {
    let value: Double
    var height: CGFloat = 3
    var tint = Theme.accent

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(Theme.hairline)
            Capsule()
                .fill(tint)
                .frame(width: geo.size.width * max(0, min(value, 1)))
                .animation(.spring(duration: 0.5), value: value)
        }
        .frame(height: height)
    }
}

extension Font {
    /// Numerals: tabular, so counters roll without shifting.
    static func numeral(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight).monospacedDigit()
    }
}

extension View {
    /// Fades and lifts a block into place, later blocks slightly after earlier ones.
    func rise(_ shown: Bool, order: Int) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 14)
            .animation(.spring(duration: 0.5, bounce: 0.15).delay(0.05 * Double(order)), value: shown)
    }
}
