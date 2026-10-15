import SwiftUI

// The app ships on iPhone. The macOS branches exist only so the package type-checks from the Mac CLI.
#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
extension Image {
    init(platform image: PlatformImage) { self.init(uiImage: image) }
}
#else
import AppKit
public typealias PlatformImage = NSImage
extension Image {
    init(platform image: PlatformImage) { self.init(nsImage: image) }
}
#endif

/// Foodie palette: an off-white page, white cards, one tangerine family that does all the
/// work (hero, buttons, progress, selection), near-black ink. Green and red only mean keep / delete.
/// Warren picked Tangerine over Grape and Berry on 15 Oct 2026.
enum Theme {
    static let b700 = Color(hex: 0xE2520F)
    static let b500 = Color(hex: 0xFF8A1F)
    static let b300 = Color(hex: 0xFFC98E)
    static let b100 = Color(hex: 0xFFF0E2)

    static let page = Color(hex: 0xF5F4F2)
    static let card = Color.white
    static let fill = Color(hex: 0xEDEBEF)
    static let ink = Color(hex: 0x17151F)
    static let muted = Color(hex: 0x6B6878)
    static let dim = Color(hex: 0x9C99A6)
    static let hairline = Color(hex: 0x17151F).opacity(0.08)
    static let accent = b500
    static let keep = Color(hex: 0x16A363)
    static let delete = Color(hex: 0xE5484D)

    static let hero = LinearGradient(colors: [b700, b500], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cta = LinearGradient(colors: [b500, b700], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let keepFill = LinearGradient(colors: [Color(hex: 0x2BC27B), keep], startPoint: .top, endPoint: .bottom)
    static let deleteFill = LinearGradient(colors: [Color(hex: 0xFF6B6F), delete], startPoint: .top, endPoint: .bottom)
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

/// Haptics on every press. The Settings switch is read straight from defaults so any view can buzz.
enum Haptics {
    private static var on: Bool { UserDefaults.standard.object(forKey: "haptics") as? Bool ?? true }

    /// A soft touch as a finger lands on any button.
    static func press() {
        #if canImport(UIKit)
        if on { UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: 0.7) }
        #endif
    }

    static func tap(_ enabled: Bool) {
        #if canImport(UIKit)
        if enabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
        #endif
    }

    /// The swipe verdict: a firmer thud than a button.
    static func thud(_ enabled: Bool) {
        #if canImport(UIKit)
        if enabled { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
        #endif
    }

    static func tick(_ enabled: Bool) {
        #if canImport(UIKit)
        if enabled { UISelectionFeedbackGenerator().selectionChanged() }
        #endif
    }

    static func success(_ enabled: Bool) {
        #if canImport(UIKit)
        if enabled { UINotificationFeedbackGenerator().notificationOccurred(.success) }
        #endif
    }

    static func warning(_ enabled: Bool) {
        #if canImport(UIKit)
        if enabled { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
        #endif
    }
}

extension View {
    /// Full screen on iPhone; a plain sheet where full-screen covers do not exist.
    func cover<Item: Identifiable, Content: View>(item: Binding<Item?>, @ViewBuilder content: @escaping (Item) -> Content) -> some View {
        #if os(iOS)
        fullScreenCover(item: item, content: content)
        #else
        sheet(item: item, content: content)
        #endif
    }

    func hideNavBar() -> some View {
        #if os(iOS)
        toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }

    /// Marks the view a full-screen cover grows out of (the Photos-style zoom).
    @ViewBuilder func zoomSource(_ id: String, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
        matchedTransitionSource(id: id, in: namespace)
        #else
        self
        #endif
    }

    @ViewBuilder func zoomTransition(_ id: String, in namespace: Namespace.ID) -> some View {
        #if os(iOS)
        navigationTransition(.zoom(sourceID: id, in: namespace))
        #else
        self
        #endif
    }

    func hideStatusBar() -> some View {
        #if os(iOS)
        statusBarHidden()
        #else
        self
        #endif
    }

    func inlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

/// Every tappable surface squashes a little and buzzes softly under the finger.
struct PressStyle: ButtonStyle {
    var haptic = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in
                if down && haptic { Haptics.press() }
            }
    }
}

/// For large tappable areas (a whole month card): a smaller squash.
struct DimStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, down in
                if down { Haptics.press() }
            }
    }
}

extension View {
    /// Small label above or beside a larger name.
    func eyebrow() -> some View {
        font(.subheadline.weight(.medium))
            .foregroundStyle(Theme.dim)
    }

    /// White card: no border, a soft long shadow, a big radius.
    func card(_ radius: CGFloat = 28) -> some View {
        background(Theme.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .shadow(color: Theme.ink.opacity(0.06), radius: 16, y: 8)
    }

    /// A row heading on the home feed: bold name, optional quiet action on the right.
    func sectionTitle() -> some View {
        font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(Theme.ink)
    }
}

/// Apple lets apps open Photos but not a specific album.
func openPhotosApp() {
    #if canImport(UIKit)
    if let url = URL(string: "photos-redirect://") { UIApplication.shared.open(url) }
    #endif
}

func openSystemSettings() {
    #if canImport(UIKit)
    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    #endif
}

let byteFormatter: ByteCountFormatter = {
    let f = ByteCountFormatter()
    f.countStyle = .file
    f.allowsNonnumericFormatting = false
    return f
}()

/// "0 MB" reads better than "0 bytes" before anything has been freed.
func formatBytes(_ bytes: Int64) -> String {
    bytes == 0 ? "0 MB" : byteFormatter.string(fromByteCount: bytes)
}
