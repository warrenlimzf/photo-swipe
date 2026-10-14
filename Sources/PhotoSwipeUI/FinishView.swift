import SwiftUI

/// The end of a deck: a tick that draws itself, the album emojis bursting out, and what got sorted.
struct FinishView: View {
    let heading: String
    let kept: Int
    let marked: Int
    /// Emoji and how many photos went into that album during this deck, in rail order.
    let filed: [(String, Int)]
    let pending: Int
    let nextTitle: String?
    let onNext: () -> Void
    let onReview: () -> Void
    let onDone: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(RadialGradient(colors: [Theme.keep.opacity(0.35), .clear], center: .center, startRadius: 10, endRadius: 150))
                    .frame(width: 300, height: 300)
                    .opacity(shown ? 1 : 0)
                if !reduceMotion { Burst(emojis: burstEmojis, fired: shown) }
                Circle()
                    .fill(Theme.keep)
                    .frame(width: 100, height: 100)
                    .shadow(color: Theme.keep.opacity(0.5), radius: 24)
                    .scaleEffect(shown || reduceMotion ? 1 : 0.6)
                DrawnTick()
                    .trim(from: 0, to: shown ? 1 : 0)
                    .stroke(Theme.canvas, style: StrokeStyle(lineWidth: 9, lineCap: .round, lineJoin: .round))
                    .frame(width: 100, height: 100)
            }
            .frame(height: 210)
            Text(heading)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 10)
            Text(summary)
                .font(.body)
                .monospacedDigit()
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.muted)
                .opacity(shown ? 1 : 0)
            VStack(spacing: 10) {
                if let nextTitle {
                    PrimaryButton(title: "Next: \(nextTitle)", color: Theme.keep, action: onNext)
                } else if pending == 0 {
                    PrimaryButton(title: "Back to library", color: Theme.keep, action: onDone)
                }
                if pending > 0 {
                    Button(pending == 1 ? "Review 1 to delete" : "Review \(pending) to delete", action: onReview)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.delete)
                        .frame(minHeight: 44)
                }
                if nextTitle != nil || pending > 0 {
                    Button("Back to library", action: onDone)
                        .font(.body.weight(.medium))
                        .foregroundStyle(Theme.muted)
                        .frame(minHeight: 44)
                }
            }
            .padding(.top, 8)
            .opacity(shown ? 1 : 0)
        }
        .foregroundStyle(Theme.ink)
        .padding(24)
        .onAppear {
            if reduceMotion {
                shown = true
            } else {
                withAnimation(.spring(duration: 0.55, bounce: 0.4)) { shown = true }
            }
        }
    }

    private var summary: String {
        var parts = ["\(kept) kept"]
        if marked > 0 { parts.append("\(marked) to delete") }
        let line = parts.joined(separator: " · ")
        let albums = filed.map { "\($1) into \($0)" }.joined(separator: " · ")
        return albums.isEmpty ? line : line + "\n" + albums
    }

    private var burstEmojis: [String] {
        let picks = filed.map(\.0)
        return picks.isEmpty ? ["✨", "🎉", "✨"] : picks
    }
}

/// A check mark as a path, so `trim` can draw it in.
private struct DrawnTick: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.width * 0.29, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.44, y: rect.height * 0.67))
        path.addLine(to: CGPoint(x: rect.width * 0.73, y: rect.height * 0.36))
        return path
    }
}

/// Emojis flying out from the tick once, then fading.
private struct Burst: View {
    let emojis: [String]
    let fired: Bool
    private let count = 12

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let angle = Double(i) / Double(count) * 2 * .pi + 0.3
                let distance: CGFloat = i.isMultiple(of: 2) ? 120 : 92
                Text(emojis[i % emojis.count])
                    .font(.system(size: i.isMultiple(of: 3) ? 30 : 22))
                    .offset(x: fired ? cos(angle) * distance : 0, y: fired ? sin(angle) * distance : 0)
                    .scaleEffect(fired ? 1 : 0.3)
                    .opacity(fired ? 0 : 1)
                    .animation(.easeOut(duration: 1.1).delay(0.15), value: fired)
            }
        }
    }
}
