import SwiftUI

public struct RootView: View {
    @State private var model = AppModel()
    @State private var store = Store()
    /// Lags `store.unlocked` by a beat on purchase, so the confetti plays before the app opens.
    @State private var gated: Bool?
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            Group {
                if gated ?? !store.unlocked {
                    GateView(ready: !showSplash)
                } else if model.library.access == .granted {
                    HomeView(ready: !showSplash)
                } else {
                    PermissionView(ready: !showSplash)
                }
            }
            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(1)
            }
        }
        .environment(model)
        .environment(store)
        .onChange(of: store.unlocked) { old, now in
            if gated == nil { gated = !old }
            if now {
                Task {
                    try? await Task.sleep(for: .milliseconds(1800))
                    withAnimation(.easeInOut(duration: 0.45)) { gated = false }
                }
            } else {
                gated = true
            }
        }
        .tint(Theme.b500)
        // Every screen starts on the orange hero, so the window asks for dark (white clock) while
        // the views themselves draw light.
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.dark)
        .task(id: model.library.access) { await model.reload() }
        .task {
            // The splash covers the first library read, then gets out of the way.
            try? await Task.sleep(for: .milliseconds(850))
            withAnimation(.easeOut(duration: 0.3)) { showSplash = false }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                model.library.refreshAccess()
                // Albums may have changed in the Photos app while this one was in the background.
                Task { await model.refreshAlbums() }
            } else {
                model.saveNow()
            }
        }
    }
}

/// Launch: the prints slide in from the left on the brand colour, the wordmark fades in under them.
private struct SplashView: View {
    @State private var shown = false

    var body: some View {
        VStack(spacing: 18) {
            PrintStack(size: 190, animated: false, spread: shown ? 1 : 0)
                .offset(x: shown ? 0 : -260)
                .rotationEffect(.degrees(shown ? 0 : -12))
            Wordmark(size: 30)
                .opacity(shown ? 1 : 0)
                .offset(y: shown ? 0 : 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.hero.ignoresSafeArea())
        .onAppear {
            withAnimation(.spring(duration: 0.65, bounce: 0.3)) { shown = true }
        }
    }
}

/// First run, shaped like Foodie's login: the brand block with the drawing on top, a white
/// sheet with one heading, three short lines and the one button.
struct PermissionView: View {
    let ready: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ZStack(alignment: .bottomLeading) {
                    HeroShape(radius: 44)
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 8) {
                            Wordmark(size: 30)
                            Text("Swipe your camera roll clean.")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .rise(ready, order: 1)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                    PrintStack(size: 210, spread: ready ? 1 : 0)
                        .animation(.spring(duration: 0.7, bounce: 0.3).delay(0.1), value: ready)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(.top, geo.safeAreaInsets.top + 24)
                        .padding(.trailing, 14)
                }
                .frame(height: geo.safeAreaInsets.top + geo.size.height * 0.48)
                .offset(y: ready ? 0 : -40)
                .animation(.spring(duration: 0.6, bounce: 0.2), value: ready)

                VStack(alignment: .leading, spacing: 18) {
                    FeatureRow(icon: "hand.draw.fill", text: "Right keeps, left deletes").rise(ready, order: 2)
                    FeatureRow(icon: "checkmark.shield.fill", text: "Nothing goes until you confirm").rise(ready, order: 3)
                    FeatureRow(icon: "lock.fill", text: "Photos stay on this phone").rise(ready, order: 4)
                    Spacer(minLength: 0)
                    Group {
                        if model.library.access == .denied {
                            VStack(spacing: 12) {
                                Text("Photo access is off.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.muted)
                                Pill(title: "Open Settings", icon: "gearshape.fill") { openSystemSettings() }
                            }
                        } else {
                            Pill(title: "Allow photos", icon: "photo.on.rectangle.angled") {
                                Task { await model.library.requestAccess() }
                            }
                        }
                    }
                    .rise(ready, order: 5)
                }
                .padding(.horizontal, 24)
                .padding(.top, 34)
                .padding(.bottom, geo.safeAreaInsets.bottom + 12)
            }
            .ignoresSafeArea()
        }
        .background(Theme.page.ignoresSafeArea())
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.b500)
                .frame(width: 48, height: 48)
                .background(Theme.b100, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            Text(text)
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(Theme.ink)
        }
    }
}

/// A photo or video poster frame from the library. Fades in when it arrives.
struct AssetImage: View {
    let id: String
    let side: CGFloat
    var fill = false
    /// Off when another image sits underneath as the stand-in.
    var placeholder = true
    @Environment(AppModel.self) private var model
    @State private var image: PlatformImage?

    var body: some View {
        let shown = image ?? model.library.cachedImage(for: id, side: side)
        ZStack {
            if placeholder { Theme.fill }
            if let image = shown {
                Image(platform: image)
                    .resizable()
                    .aspectRatio(contentMode: fill ? .fill : .fit)
                    .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.2), value: shown != nil)
        .task(id: id) { image = await model.library.image(for: id, side: side) }
    }
}

/// A photo that fills whatever space it is given, cropped, square-cornered.
struct Tile: View {
    let id: String
    var side: CGFloat = 400

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { AssetImage(id: id, side: side, fill: true) }
            .clipped()
    }
}

/// Square thumbnail for grids, softly rounded.
struct Thumb: View {
    let id: String

    var body: some View {
        Tile(id: id, side: 300)
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

let thumbColumns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
