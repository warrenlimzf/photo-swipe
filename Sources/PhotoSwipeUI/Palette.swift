import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// The colour themes the user can pick in Settings → Colours. Each is a small gradient family:
/// nine mesh colours for the hero (top row first) and four accent shades for buttons, bars and
/// selection. Green and red stay fixed for keep / delete in every theme.
enum Palette: String, CaseIterable, Identifiable {
    case tangerine, sunset, aurora, ocean, berry, midnight

    var id: Self { self }
    var name: String { rawValue.capitalized }

    /// Alternate app icon in the asset catalog; nil is the main icon.
    var iconName: String? { self == .tangerine ? nil : "AppIcon-\(name)" }

    var mesh: [Color] {
        let hex: [UInt32] = switch self {
        case .tangerine: [0xD9480F, 0xF26B1D, 0xFF9A3C, 0xEF5A14, 0xFF8A1F, 0xFFB45E, 0xFF7A1A, 0xFF9F45, 0xFFC071]
        case .sunset: [0xFF8A3D, 0xFF6B6B, 0xD9437F, 0xFF7A4D, 0xF2506E, 0xB43A8C, 0xFFB15C, 0xFF7A7A, 0x8A3FB5]
        // React Bits' Aurora default stops (#5227FF → #7CFF67), softened so white type still reads.
        case .aurora: [0x3A1FB8, 0x5227FF, 0x2F8BFF, 0x4A2BE0, 0x3B6CF0, 0x22B8A6, 0x5227FF, 0x2AA3C9, 0x6FE08A]
        case .ocean: [0x0B3D91, 0x0B5CAD, 0x0E9AAE, 0x1356B8, 0x1E86E8, 0x22B5C7, 0x1A6FD6, 0x3FA4F5, 0x6FD9D0]
        case .berry: [0x8E1550, 0xB2195F, 0xE23D85, 0xA01A6A, 0xD9337A, 0xFF6FA8, 0x6A1B9A, 0xC2307E, 0xFF9CC8]
        case .midnight: [0x0F0C1D, 0x1F1B3A, 0x3B2A6B, 0x1A1730, 0x2D2452, 0x5B3FA0, 0x15122A, 0x2E2560, 0x7B61FF]
        }
        return hex.map { Color(hex: $0) }
    }

    /// Accent shades: deep, main, light, wash.
    var shades: (UInt32, UInt32, UInt32, UInt32) {
        switch self {
        case .tangerine: (0xE2520F, 0xFF8A1F, 0xFFC98E, 0xFFF0E2)
        case .sunset: (0xC8325F, 0xFF6363, 0xFFB7A6, 0xFFEDEA)
        case .aurora: (0x4A22E0, 0x6A45FF, 0xB6A6FF, 0xEEEAFF)
        case .ocean: (0x0B5CAD, 0x1E86E8, 0x93D0FF, 0xE6F3FF)
        case .berry: (0xB2195F, 0xE23D85, 0xFF9CC8, 0xFDE8F2)
        case .midnight: (0x2A2150, 0x5B3FD9, 0xB3A4FF, 0xEEEBFF)
        }
    }
}

/// Holds the chosen palette and whether the hero colours drift. Views read it through `Theme`,
/// so changing it repaints the whole app.
@Observable final class ThemeStore {
    static let shared = ThemeStore()

    var palette: Palette {
        didSet { UserDefaults.standard.set(palette.rawValue, forKey: "palette") }
    }
    var moving: Bool {
        didSet { UserDefaults.standard.set(moving, forKey: "movingColours") }
    }

    private init() {
        palette = Palette(rawValue: UserDefaults.standard.string(forKey: "palette") ?? "") ?? .tangerine
        moving = UserDefaults.standard.object(forKey: "movingColours") as? Bool ?? true
    }

    /// Swaps the home-screen icon to match. iOS shows its own short notice when it changes.
    @MainActor func matchIcon() async -> Bool {
        #if canImport(UIKit)
        let name = palette.iconName
        guard UIApplication.shared.supportsAlternateIcons else { return false }
        if UIApplication.shared.alternateIconName == name { return true }
        do { try await UIApplication.shared.setAlternateIconName(name); return true } catch { return false }
        #else
        return true
        #endif
    }

    @MainActor var iconMatches: Bool {
        #if canImport(UIKit)
        UIApplication.shared.alternateIconName == palette.iconName
        #else
        true
        #endif
    }
}

/// The hero's colour: a 3×3 mesh in the palette's colours whose inner points drift slowly, the
/// native take on React Bits' Aurora. Still under Reduce Motion or when Moving colours is off.
struct HeroFill: View {
    var palette: Palette = Theme.palette
    var animated = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if animated && ThemeStore.shared.moving && !reduceMotion {
            TimelineView(.animation(minimumInterval: 1 / 30)) { context in
                mesh(t: context.date.timeIntervalSinceReferenceDate)
            }
        } else {
            mesh(t: 0)
        }
    }

    private func mesh(t: Double) -> some View {
        func drift(_ phase: Double, _ speed: Double) -> Float { Float(sin(t * speed + phase) * 0.12) }
        let points: [SIMD2<Float>] = [
            [0, 0], [0.5 + drift(0, 0.31), 0], [1, 0],
            [0, 0.5 + drift(1.3, 0.27)], [0.5 + drift(2.1, 0.23), 0.5 + drift(0.7, 0.29)], [1, 0.5 + drift(2.9, 0.25)],
            [0, 1], [0.5 + drift(3.7, 0.33), 1], [1, 1],
        ]
        return MeshGradient(width: 3, height: 3, points: points, colors: palette.mesh, smoothsColors: true)
    }
}

/// Settings → Colours: pick a palette (the hero above repaints live), let the colours drift or
/// hold still, and set the matching app icon.
struct ColoursView: View {
    @State private var iconMatches = true
    @State private var settingIcon = false

    var body: some View {
        @Bindable var store = ThemeStore.shared
        HeroScreen(title: "Colours", subtitle: store.palette.name) {
            VStack(spacing: 16) {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 16) {
                    ForEach(Palette.allCases) { option in
                        swatch(option, selected: option == store.palette)
                    }
                }
                .padding(14)
                .card(26)

                VStack(spacing: 0) {
                    HStack(spacing: 14) {
                        rowIcon("wind")
                        Toggle("Moving colours", isOn: $store.moving)
                            .tint(Theme.b500)
                            .sensoryFeedback(.selection, trigger: store.moving)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    Rectangle().fill(Theme.hairline).frame(height: 1).padding(.leading, 66)
                    HStack(spacing: 14) {
                        HeroFill(animated: false)
                            .frame(width: 36, height: 36)
                            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        Text("App icon").foregroundStyle(Theme.ink)
                        Spacer()
                        if iconMatches {
                            Label("Matches", systemImage: "checkmark")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(Theme.keep)
                                .transition(.scale(scale: 0.8).combined(with: .opacity))
                        } else {
                            Button {
                                settingIcon = true
                                Task {
                                    let done = await store.matchIcon()
                                    if done { Haptics.success(true) }
                                    withAnimation(.spring(duration: 0.35)) { iconMatches = store.iconMatches }
                                    settingIcon = false
                                }
                            } label: {
                                Group {
                                    if settingIcon { ProgressView().tint(.white) } else { Text("Match") }
                                }
                                .font(.system(.subheadline, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .frame(height: 36)
                                .background(Theme.cta, in: Capsule())
                            }
                            .buttonStyle(PressStyle())
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .padding(.vertical, 6)
                .card(26)
            }
            .padding(.horizontal, 16)
        }
        .onAppear { iconMatches = store.iconMatches }
        .onChange(of: store.palette) { _, _ in
            withAnimation(.spring(duration: 0.35)) { iconMatches = store.iconMatches }
        }
    }

    private func swatch(_ option: Palette, selected: Bool) -> some View {
        Button {
            Haptics.tick(true)
            withAnimation(.smooth(duration: 0.5)) { ThemeStore.shared.palette = option }
        } label: {
            VStack(spacing: 8) {
                HeroFill(palette: option, animated: selected)
                    .frame(height: 86)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(.white, lineWidth: selected ? 3 : 0)
                    }
                    .overlay(alignment: .topTrailing) {
                        if selected {
                            Image(systemName: "checkmark")
                                .font(.caption.weight(.heavy))
                                .foregroundStyle(Color(hex: option.shades.0))
                                .frame(width: 24, height: 24)
                                .background(.white, in: Circle())
                                .padding(7)
                                .transition(.scale(scale: 0.4).combined(with: .opacity))
                        }
                    }
                    .shadow(color: Color(hex: option.shades.1).opacity(selected ? 0.45 : 0.15), radius: selected ? 12 : 6, y: 5)
                    .scaleEffect(selected ? 1.04 : 1)
                Text(option.name)
                    .font(.system(.subheadline, design: .rounded, weight: selected ? .bold : .medium))
                    .foregroundStyle(selected ? Theme.ink : Theme.muted)
            }
        }
        .buttonStyle(PressStyle(haptic: false))
        .animation(.spring(duration: 0.4, bounce: 0.35), value: selected)
        .accessibilityLabel("\(option.name) colours")
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    private func rowIcon(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Theme.b500)
            .frame(width: 36, height: 36)
            .background(Theme.b500.opacity(0.12), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
