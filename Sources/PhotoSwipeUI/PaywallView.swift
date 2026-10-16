import SwiftUI
import SwipeCore

/// Before the app: three intro pages, then the paywall. One price, once, for life.
struct GateView: View {
    let ready: Bool
    @Environment(Store.self) private var store
    @AppStorage("gate.seenIntro") private var seenIntro = false

    var body: some View {
        ZStack {
            switch AccessGate.screen(seenIntro: seenIntro, unlocked: store.unlocked) {
            case .intro:
                IntroView(ready: ready) {
                    withAnimation(.spring(duration: 0.5, bounce: 0.15)) { seenIntro = true }
                }
                .transition(.move(edge: .leading).combined(with: .opacity))
            case .paywall, .app:
                PaywallView(ready: ready)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
    }
}

// MARK: - Intro

private struct IntroPage: Identifiable {
    let id: Int
    let title: String
    let line: String
}

private let introPages = [
    IntroPage(id: 0, title: "Swipe your camera roll clean.", line: "Right keeps. Left deletes. One photo at a time."),
    IntroPage(id: 1, title: "Nothing goes by accident.", line: "Undo any swipe. You confirm every delete on one last screen."),
    IntroPage(id: 2, title: "File as you go.", line: "Tap an emoji album while you swipe. Photos never leave your phone."),
]

/// Three pages on the brand colour, each with its own little drawing, a dot row and one button.
struct IntroView: View {
    let ready: Bool
    let done: () -> Void
    @State private var page = 0

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack {
                    HeroShape(radius: 44)
                    pages
                        .padding(.top, geo.safeAreaInsets.top + 20)
                }
                .frame(height: geo.safeAreaInsets.top + geo.size.height * 0.62)

                VStack(spacing: 22) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(introPages[page].title)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(Theme.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(introPages[page].line)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Theme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(page)
                    .transition(.asymmetric(insertion: .offset(x: 30).combined(with: .opacity), removal: .opacity))
                    .rise(ready, order: 2)

                    Spacer(minLength: 0)
                    HStack(spacing: 8) {
                        ForEach(introPages) { p in
                            Capsule()
                                .fill(p.id == page ? AnyShapeStyle(Theme.cta) : AnyShapeStyle(Theme.fill))
                                .frame(width: p.id == page ? 26 : 8, height: 8)
                        }
                    }
                    .animation(.spring(duration: 0.4), value: page)
                    Pill(title: page == introPages.count - 1 ? "Continue" : "Next", icon: "arrow.right") {
                        Haptics.press()
                        if page < introPages.count - 1 {
                            withAnimation(.spring(duration: 0.45, bounce: 0.2)) { page += 1 }
                        } else {
                            done()
                        }
                    }
                    .rise(ready, order: 3)
                }
                .padding(.horizontal, 24)
                .padding(.top, 30)
                .padding(.bottom, geo.safeAreaInsets.bottom + 12)
            }
            .ignoresSafeArea()
        }
        .background(Theme.page.ignoresSafeArea())
    }

    @ViewBuilder private var pages: some View {
        #if os(iOS)
        TabView(selection: $page.animation(.spring(duration: 0.45, bounce: 0.2))) {
            ForEach(introPages) { p in
                IntroArt(index: p.id, active: page == p.id).tag(p.id)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        #else
        IntroArt(index: page, active: true)
        #endif
    }
}

/// The drawing on each intro page. Page one is the self-swiping prints; two is a confirm grid;
/// three is emoji albums popping up under a print.
private struct IntroArt: View {
    let index: Int
    let active: Bool
    @State private var shown = false

    var body: some View {
        Group {
            switch index {
            case 0:
                PrintStack(size: 230, spread: shown ? 1 : 0)
            case 1:
                ConfirmGrid(shown: shown)
            default:
                AlbumChips(shown: shown)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: active, initial: true) { _, now in
            withAnimation(.spring(duration: 0.7, bounce: 0.3).delay(now ? 0.1 : 0)) { shown = now }
        }
    }
}

/// A 3×3 grid of white tiles; four flip to red "delete" crosses, then a tick button lands.
private struct ConfirmGrid: View {
    let shown: Bool
    private let marked: Set<Int> = [1, 3, 5, 7]

    var body: some View {
        VStack(spacing: 18) {
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(62), spacing: 8), count: 3), spacing: 8) {
                ForEach(0..<9, id: \.self) { i in
                    let on = shown && marked.contains(i)
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(.white.opacity(on ? 1 : 0.85))
                        .frame(width: 62, height: 62)
                        .overlay {
                            Image(systemName: on ? "xmark" : "photo")
                                .font(.system(size: on ? 22 : 18, weight: .bold))
                                .foregroundStyle(on ? Theme.delete : Theme.dim)
                                .contentTransition(.symbolEffect(.replace))
                        }
                        .scaleEffect(shown ? 1 : 0.6)
                        .opacity(shown ? 1 : 0)
                        .animation(.spring(duration: 0.5, bounce: 0.35).delay(0.04 * Double(i)), value: shown)
                }
            }
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                Text("Delete 4")
            }
            .font(.system(.headline, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 22)
            .frame(height: 46)
            .background(Theme.deleteFill, in: Capsule())
            .scaleEffect(shown ? 1 : 0.4)
            .opacity(shown ? 1 : 0)
            .animation(.spring(duration: 0.55, bounce: 0.4).delay(0.45), value: shown)
        }
    }
}

/// One print, with three emoji album chips bouncing up beneath it.
private struct AlbumChips: View {
    let shown: Bool
    private let chips = ["✈️ Trips", "🍜 Food", "🌄 Views"]

    var body: some View {
        VStack(spacing: 22) {
            PrintStack(size: 170, animated: false, spread: shown ? 0.5 : 0)
            HStack(spacing: 8) {
                ForEach(Array(chips.enumerated()), id: \.offset) { i, chip in
                    Text(chip)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(i == 1 ? .white : Theme.ink)
                        .padding(.horizontal, 14)
                        .frame(height: 38)
                        .background {
                            if i == 1 { Capsule().fill(Theme.cta) } else { Capsule().fill(.white) }
                        }
                        .offset(y: shown ? 0 : 40)
                        .opacity(shown ? 1 : 0)
                        .animation(.spring(duration: 0.55, bounce: 0.45).delay(0.15 + 0.08 * Double(i)), value: shown)
                }
            }
        }
    }
}

// MARK: - Paywall

/// The paywall: what you get, how little it costs, one button. Apple shows its own purchase
/// sheet on top, so this screen never touches card details.
struct PaywallView: View {
    let ready: Bool
    @Environment(Store.self) private var store
    @Environment(\.openURL) private var openURL
    @State private var celebrate = false

    /// PLACEHOLDERS: App Store Connect needs a privacy policy URL; Terms can stay Apple's
    /// standard licence (EULA) unless you write your own.
    static let privacyURL = URL(string: "https://warrenlimzf.com/photo-swipe/privacy")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    private let perks: [(String, String)] = [
        ("infinity", "Every photo, no swipe limits"),
        ("checkmark.shield.fill", "Undo and a final check before deletes"),
        ("face.smiling.inverse", "Emoji albums while you swipe"),
        ("paintpalette.fill", "All six colours and app icons"),
        ("lock.fill", "No ads, no account, no tracking"),
        ("sparkles", "Every future update"),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        hero(top: geo.safeAreaInsets.top)
                        VStack(spacing: 18) {
                            perksCard.rise(ready, order: 2)
                            OnceVsYearly().rise(ready, order: 3)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 200)
                    }
                }
                .noTopEdgeEffect()
                .scrollIndicators(.hidden)

                VStack {
                    Spacer()
                    buyBar(bottom: geo.safeAreaInsets.bottom)
                }
                if celebrate { Confetti().allowsHitTesting(false) }
            }
            .ignoresSafeArea()
        }
        .background(Theme.page.ignoresSafeArea())
        .onChange(of: store.unlocked) { _, now in
            // Covers Buy, Restore and an Ask to Buy approval arriving later alike.
            if now { Haptics.success(true); celebrate = true }
        }
    }

    private func hero(top: CGFloat) -> some View {
        ZStack(alignment: .bottomLeading) {
            HeroShape(radius: 44)
            PrintStack(size: 150)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(.top, top + 18)
                .padding(.trailing, 10)
            VStack(alignment: .leading, spacing: 6) {
                Text("Lifetime")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 12)
                    .frame(height: 28)
                    .background(.white.opacity(0.2), in: Capsule())
                Text(store.price)
                    .font(.numeral(64, weight: .heavy))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
                    .animation(.spring(duration: 0.5), value: store.price)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("Pay once. Keep it forever.")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 28)
            .rise(ready, order: 1)
        }
        .frame(height: top + 330)
    }

    private var perksCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Everything, unlocked")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            ForEach(Array(perks.enumerated()), id: \.offset) { i, perk in
                HStack(spacing: 14) {
                    Image(systemName: perk.0)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.b500)
                        .frame(width: 40, height: 40)
                        .background(Theme.b100, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    Text(perk.1)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(Theme.ink)
                    Spacer(minLength: 0)
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.keep)
                        .symbolEffect(.bounce, value: ready)
                }
                .rise(ready, order: 3 + i)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.ink.opacity(0.06), radius: 16, y: 8)
    }

    private func buyBar(bottom: CGFloat) -> some View {
        VStack(spacing: 12) {
            status
            Pill(
                title: store.phase == .buying ? "Opening the App Store…" : "Unlock for \(store.price)",
                icon: "lock.open.fill",
                busy: store.phase == .buying
            ) {
                Haptics.press()
                store.clearError()
                Task { await store.buy() }
            }
            Text("One-time purchase through Apple. No subscription.")
                .font(.footnote)
                .foregroundStyle(Theme.muted)
            HStack(spacing: 18) {
                Button(store.restoring ? "Restoring…" : "Restore purchase") {
                    Haptics.press()
                    store.clearError()
                    Task { await store.restore() }
                }
                .disabled(store.restoring)
                Button("Terms") { openURL(Self.termsURL) }
                Button("Privacy") { openURL(Self.privacyURL) }
                #if DEBUG
                Button("Skip (debug)") { store.developerUnlock() }
                #endif
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.b700)
            .buttonStyle(PressStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, bottom + 10)
        .background {
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 1) }
                .ignoresSafeArea()
        }
        .rise(ready, order: 4)
    }

    @ViewBuilder private var status: some View {
        switch store.phase {
        case .pending:
            banner("hourglass", "Waiting for approval. Photo Swipe unlocks as soon as it's approved.", Theme.b700)
        case .failed(let message):
            banner("exclamationmark.circle.fill", message, Theme.delete)
        default:
            EmptyView()
        }
    }

    private func banner(_ icon: String, _ text: String, _ tint: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
            Text(text).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(tint)
        .padding(14)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

/// Three years side by side: a yearly plan's bars keep growing, the one-off stays put.
private struct OnceVsYearly: View {
    @State private var shown = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Once, not every year")
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(Theme.ink)
            HStack(alignment: .bottom, spacing: 18) {
                ForEach(1...3, id: \.self) { year in
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 6) {
                            bar(height: shown ? CGFloat(year) * 34 : 4, fill: AnyShapeStyle(Theme.fill))
                            bar(height: shown ? 14 : 4, fill: AnyShapeStyle(Theme.cta))
                        }
                        .frame(height: 104, alignment: .bottom)
                        Text("Year \(year)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.muted)
                    }
                    .animation(.spring(duration: 0.7, bounce: 0.25).delay(0.12 * Double(year)), value: shown)
                }
            }
            .frame(maxWidth: .infinity)
            HStack(spacing: 16) {
                legend(AnyShapeStyle(Theme.fill), "Yearly plan")
                legend(AnyShapeStyle(Theme.cta), "Photo Swipe")
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Theme.ink.opacity(0.06), radius: 16, y: 8)
        .onScrollVisibilityChange(threshold: 0.5) { visible in
            if visible { shown = true }
        }
    }

    private func bar(height: CGFloat, fill: AnyShapeStyle) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous).fill(fill).frame(width: 26, height: height)
    }

    private func legend(_ fill: AnyShapeStyle, _ text: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(fill).frame(width: 10, height: 10)
            Text(text).font(.caption.weight(.semibold)).foregroundStyle(Theme.muted)
        }
    }
}

/// A short burst of brand-coloured paper when the purchase lands.
private struct Confetti: View {
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let pieces: [(x: Double, speed: Double, spin: Double, hue: Int, size: Double)] = (0..<70).map { _ in
        (Double.random(in: 0...1), Double.random(in: 260...520), Double.random(in: -6...6), Int.random(in: 0...3), Double.random(in: 6...11))
    }

    var body: some View {
        if !reduceMotion {
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSince(start)
                Canvas { context, size in
                    let colors = [Theme.b300, Theme.b500, Theme.keep, Color.white]
                    for piece in pieces {
                        let y = -20 + piece.speed * t + 160 * t * t
                        guard y < size.height + 20 else { continue }
                        let x = piece.x * size.width + sin(t * 3 + piece.x * 10) * 18
                        var c = context
                        c.translateBy(x: x, y: y)
                        c.rotate(by: .radians(piece.spin * t))
                        c.opacity = max(0, 1 - t / 2.6)
                        c.fill(Path(CGRect(x: -piece.size / 2, y: -piece.size / 4, width: piece.size, height: piece.size / 2)),
                               with: .color(colors[piece.hue]))
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}
