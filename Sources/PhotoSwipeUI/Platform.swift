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

/// Gallery palette: always dark so the photos carry the colour.
/// A cool off-black (pure black reads as unstyled), warm white type, and two soft verdict colours.
enum Theme {
    static let canvas = Color(red: 0.043, green: 0.051, blue: 0.059)
    static let card = Color(red: 0.086, green: 0.098, blue: 0.110)
    static let ink = Color(red: 0.957, green: 0.945, blue: 0.918)
    static let muted = ink.opacity(0.55)
    static let hairline = ink.opacity(0.10)
    static let accent = ink
    static let keep = Color(red: 0.435, green: 0.812, blue: 0.592)
    static let delete = Color(red: 1.0, green: 0.42, blue: 0.37)
}

enum Haptics {
    static func tap(_ enabled: Bool) {
        #if canImport(UIKit)
        if enabled { UIImpactFeedbackGenerator(style: .medium).impactOccurred() }
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

    func inlineTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

/// Every tappable surface dips slightly while pressed.
struct PressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// For large tappable areas (a whole month): dim on press instead of shrinking.
struct DimStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

extension View {
    /// Small tracked capitals for labels that sit above or beside a larger name.
    func eyebrow() -> some View {
        font(.caption.weight(.semibold))
            .tracking(1.4)
            .textCase(.uppercase)
            .foregroundStyle(Theme.muted)
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
