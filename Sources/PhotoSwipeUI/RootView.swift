import SwiftUI

public struct RootView: View {
    @State private var model = AppModel()
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        ZStack {
            Group {
                if model.library.access == .granted {
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
        .tint(Theme.ink)
        .preferredColorScheme(.dark)
        .task(id: model.library.access) { await model.reload() }
        .task {
            // The splash covers the first library read, then gets out of the way.
            try? await Task.sleep(for: .milliseconds(850))
            withAnimation(.easeOut(duration: 0.3)) { showSplash = false }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { model.library.refreshAccess() } else { model.saveNow() }
        }
    }
}

/// Launch: the three prints fan out over black.
private struct SplashView: View {
    @State private var fanned = false

    var body: some View {
        CardFan(spread: fanned ? 1 : 0, size: 120)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.canvas.ignoresSafeArea())
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.25)) { fanned = true }
            }
    }
}

struct PermissionView: View {
    let ready: Bool
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
            CardFan(spread: ready ? 1 : 0, size: 96)
                .animation(.spring(duration: 0.6, bounce: 0.25).delay(0.1), value: ready)
                .padding(.bottom, 36)
            Text("Tidy your camera roll.")
                .font(.largeTitle.bold())
                .foregroundStyle(Theme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .rise(ready, order: 1)
            VStack(alignment: .leading, spacing: 18) {
                FeatureRow(icon: "hand.draw", text: "Right to keep, left to delete").rise(ready, order: 2)
                FeatureRow(icon: "checkmark.shield", text: "Nothing goes until you confirm").rise(ready, order: 3)
                FeatureRow(icon: "lock", text: "Your photos stay on this phone").rise(ready, order: 4)
            }
            .padding(.top, 28)
            Spacer()
            Group {
                if model.library.access == .denied {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Photo access is off. Turn it on in Settings.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.muted)
                        PrimaryButton(title: "Open Settings") { openSystemSettings() }
                    }
                } else {
                    PrimaryButton(title: "Allow photo access") {
                        Task { await model.library.requestAccess() }
                    }
                }
            }
            .rise(ready, order: 5)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.canvas.ignoresSafeArea())
    }
}

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Theme.ink)
                .frame(width: 28)
            Text(text)
                .font(.body)
                .foregroundStyle(Theme.muted)
        }
    }
}

/// The one primary action on a screen: a full-width pill. White by default.
struct PrimaryButton: View {
    let title: String
    var color: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.canvas)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(color ?? Theme.ink, in: Capsule())
        }
        .buttonStyle(PressStyle())
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
            if placeholder { Theme.card }
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

/// Square thumbnail for grids, edge to edge like the Photos app.
struct Thumb: View {
    let id: String

    var body: some View {
        Tile(id: id, side: 300).aspectRatio(1, contentMode: .fit)
    }
}

let thumbColumns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 3)
