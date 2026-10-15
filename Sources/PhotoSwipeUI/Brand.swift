import SwiftUI

/// The signature drawing: three photo prints, the top one swiping right (a tick pops) and then
/// left (a cross pops), over and over. Each print holds a little drawn landscape.
struct PrintStack: View {
    var size: CGFloat = 180
    /// Off on screens where the drawing should sit still (and always under Reduce Motion).
    var animated = true
    /// 0 = stacked, 1 = fanned out. The splash and the permission screen animate it.
    var spread: CGFloat = 1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private enum Beat: CaseIterable { case rest, keep, back, delete }

    var body: some View {
        let s = size / 200
        ZStack {
            Print(scale: s, scene: 1)
                .rotationEffect(.degrees(-13 * spread), anchor: .bottom)
                .offset(x: -30 * s * spread, y: 6 * s)
            Print(scale: s, scene: 2)
                .rotationEffect(.degrees(10 * spread), anchor: .bottom)
                .offset(x: 30 * s * spread, y: 4 * s)
            if animated && !reduceMotion {
                Print(scale: s, scene: 0)
                    .phaseAnimator(Beat.allCases) { print, beat in
                        print
                            .overlay(alignment: .topLeading) {
                                Badge(icon: "checkmark", fill: Theme.keepFill, scale: s)
                                    .scaleEffect(beat == .keep ? 1 : 0.3)
                                    .opacity(beat == .keep ? 1 : 0)
                                    .offset(x: -14 * s, y: -14 * s)
                            }
                            .overlay(alignment: .topTrailing) {
                                Badge(icon: "xmark", fill: Theme.deleteFill, scale: s)
                                    .scaleEffect(beat == .delete ? 1 : 0.3)
                                    .opacity(beat == .delete ? 1 : 0)
                                    .offset(x: 14 * s, y: -14 * s)
                            }
                            .rotationEffect(.degrees(beat == .keep ? 11 : beat == .delete ? -11 : 0), anchor: .bottom)
                            .offset(x: (beat == .keep ? 36 : beat == .delete ? -36 : 0) * s,
                                    y: (beat == .keep || beat == .delete ? -6 : 0) * s)
                    } animation: { beat in
                        switch beat {
                        case .keep, .delete: .spring(duration: 0.55, bounce: 0.35).delay(0.9)
                        case .rest, .back: .spring(duration: 0.5, bounce: 0.25).delay(0.6)
                        }
                    }
            } else {
                Print(scale: s, scene: 0)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// One print: a white frame, a sky, a sun and two hills.
private struct Print: View {
    let scale: CGFloat
    /// Picks the time of day so the three prints differ.
    let scene: Int

    var body: some View {
        let s = scale
        let w = 104 * s, h = 132 * s
        let sky: [Color] = switch scene {
        case 1: [Color(hex: 0xFFD7A8), Color(hex: 0xFFF1DE)]
        case 2: [Color(hex: 0xBFE6FF), Color(hex: 0xEAF7FF)]
        default: [Theme.b300, Theme.b100]
        }
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 14 * s, style: .continuous)
                .fill(.white)
                .shadow(color: Color(hex: 0x10082E).opacity(0.28), radius: 12 * s, y: 8 * s)
            ZStack {
                LinearGradient(colors: sky, startPoint: .top, endPoint: .bottom)
                Circle().fill(Color(hex: 0xFFC94D))
                    .frame(width: 24 * s).offset(x: 22 * s, y: -26 * s)
                Ellipse().fill(scene == 0 ? Theme.b500.opacity(0.55) : Color(hex: 0x7FBF8E))
                    .frame(width: 130 * s, height: 70 * s).offset(x: -34 * s, y: 40 * s)
                Ellipse().fill(scene == 0 ? Theme.b700 : Color(hex: 0x3E8D5B))
                    .frame(width: 140 * s, height: 66 * s).offset(x: 30 * s, y: 52 * s)
            }
            .frame(width: w - 16 * s, height: h - 38 * s)
            .clipShape(RoundedRectangle(cornerRadius: 8 * s, style: .continuous))
            .padding(.top, 8 * s)
        }
        .frame(width: w, height: h)
    }
}

private struct Badge: View {
    let icon: String
    let fill: LinearGradient
    let scale: CGFloat

    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 17 * scale, weight: .heavy))
            .foregroundStyle(.white)
            .frame(width: 36 * scale, height: 36 * scale)
            .background(fill, in: Circle())
            .overlay { Circle().strokeBorder(.white, lineWidth: 2.5 * scale) }
            .shadow(color: .black.opacity(0.25), radius: 6 * scale, y: 3 * scale)
    }
}

/// "Photo Swipe." with the full stop in the light brand tint.
struct Wordmark: View {
    var size: CGFloat = 22
    var color: Color = .white
    var dot: Color = Theme.b300

    var body: some View {
        (Text("Photo Swipe").foregroundStyle(color) + Text(".").foregroundStyle(dot))
            .font(.system(size: size, weight: .heavy, design: .rounded))
    }
}

/// A rounded progress bar in the brand colour (green once a month is done).
struct ProgressLine: View {
    let value: Double
    var height: CGFloat = 6
    var done = false
    var track = Theme.fill
    /// White fill, for a bar sitting on the brand colour.
    var onBrand = false

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(track)
            Capsule()
                .fill(onBrand ? AnyShapeStyle(.white) : done ? AnyShapeStyle(Theme.keepFill) : AnyShapeStyle(Theme.cta))
                .frame(width: max(height, geo.size.width * max(0, min(value, 1))))
                .opacity(value > 0 ? 1 : 0)
                .animation(.spring(duration: 0.5), value: value)
        }
        .frame(height: height)
    }
}

/// Full-width pill: the one primary action on a screen.
struct Pill: View {
    enum Kind { case brand, delete, keep, white, whiteDelete }
    let title: String
    var icon: String? = nil
    var kind: Kind = .brand
    var busy = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if busy {
                    ProgressView().tint(fg)
                } else if let icon {
                    Image(systemName: icon).font(.headline)
                }
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            .foregroundStyle(fg)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .background {
                switch kind {
                case .brand: Capsule().fill(Theme.cta).shadow(color: Theme.b500.opacity(0.4), radius: 14, y: 9)
                case .delete: Capsule().fill(Theme.deleteFill).shadow(color: Theme.delete.opacity(0.4), radius: 14, y: 9)
                case .keep: Capsule().fill(Theme.keepFill).shadow(color: Theme.keep.opacity(0.4), radius: 14, y: 9)
                case .white, .whiteDelete: Capsule().fill(.white).shadow(color: Theme.ink.opacity(0.08), radius: 12, y: 6)
                }
            }
        }
        .buttonStyle(PressStyle())
        .disabled(busy)
    }

    private var fg: Color {
        switch kind {
        case .white: Theme.ink
        case .whiteDelete: Theme.delete
        default: .white
        }
    }
}

/// The colour block on top of every pushed screen: a big white title on brand colour with
/// rounded bottom corners, the short form of the Library's hero.
struct CompactHero<Trailing: View>: View {
    let title: String
    var subtitle: String? = nil
    let topInset: CGFloat
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HeroShape(radius: 32)
            HStack(alignment: .bottom, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.75))
                            .contentTransition(.numericText())
                    }
                    Text(title)
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                Spacer(minLength: 0)
                trailing
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 20)
        }
        .frame(height: topInset + (subtitle == nil ? 76 : 96))
    }
}

/// The brand block itself: the moving mesh, a soft glow top right, rounded bottom corners.
struct HeroShape: View {
    var radius: CGFloat = 40

    var body: some View {
        let shape = UnevenRoundedRectangle(bottomLeadingRadius: radius, bottomTrailingRadius: radius, style: .continuous)
        HeroFill()
            .overlay(alignment: .topTrailing) {
                Circle().fill(.white.opacity(0.14)).frame(width: 300).blur(radius: 70).offset(x: 110, y: -120)
            }
            .clipShape(shape)
    }
}

/// A pushed screen: the compact hero, then content on the off-white page. The system back
/// button and toolbar stay (so the edge swipe back still works); only their background goes.
struct HeroScreen<Trailing: View, Content: View>: View {
    let title: String
    var subtitle: String? = nil
    @ViewBuilder var trailing: Trailing
    @ViewBuilder var content: Content
    @State private var scrolled = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 0) {
                        CompactHero(title: title, subtitle: subtitle, topInset: geo.safeAreaInsets.top) { trailing }
                        content.padding(.top, 20)
                    }
                    .padding(.bottom, 40)
                }
                .noTopEdgeEffect()
                .onScrollGeometryChange(for: Bool.self) { $0.contentOffset.y + $0.contentInsets.top > 56 } action: { _, now in
                    scrolled = now
                }
                StatusScrim(height: geo.safeAreaInsets.top, shown: scrolled)
            }
            .ignoresSafeArea(edges: .top)
        }
        .background(Theme.page.ignoresSafeArea())
        .heroBar()
    }
}

/// Once the hero scrolls away, a strip of brand colour fades in behind the status bar (and the
/// back button), so the white clock never sits on the off-white page. Place it in a top-aligned
/// stack that ignores the top safe area, with the inset as its height.
struct StatusScrim: View {
    let height: CGFloat
    let shown: Bool

    var body: some View {
        Theme.hero
            .frame(height: height)
            .shadow(color: Theme.b700.opacity(shown ? 0.25 : 0), radius: 8, y: 3)
            .opacity(shown ? 1 : 0)
            .animation(.easeOut(duration: 0.2), value: shown)
            .allowsHitTesting(false)
    }
}

extension HeroScreen where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() }, content: content)
    }
}

extension View {
    /// A see-through navigation bar with white controls, for screens that start with a hero.
    @ViewBuilder func heroBar() -> some View {
        #if os(iOS)
        // A "visible" but clear bar background, so the dark scheme also turns the status bar white.
        self
            .toolbarBackground(Color.clear, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .principal) { Color.clear.frame(width: 1, height: 1) } }
        #else
        self
        #endif
    }
}

extension View {
    /// iOS 26 blurs content under the bar; over a hero that only greys the colour.
    @ViewBuilder func noTopEdgeEffect() -> some View {
        #if os(iOS)
        if #available(iOS 26, *) { scrollEdgeEffectHidden(true, for: .top) } else { self }
        #else
        self
        #endif
    }
}

extension Font {
    /// Numerals: SF Rounded, tabular, so counters roll without shifting.
    static func numeral(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

extension View {
    /// Fades and lifts a block into place, later blocks slightly after earlier ones.
    func rise(_ shown: Bool, order: Int) -> some View {
        opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : 18)
            .animation(.spring(duration: 0.55, bounce: 0.2).delay(0.06 * Double(order)), value: shown)
    }
}
