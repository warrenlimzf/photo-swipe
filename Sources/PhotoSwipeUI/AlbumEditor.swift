import SwiftUI
import SwipeCore

/// What the album sheet is open for.
enum EditorTarget: Identifiable {
    case new
    case edit(ShelfAlbum)

    var id: String {
        switch self {
        case .new: "new"
        case .edit(let album): album.id
        }
    }

    var album: ShelfAlbum? {
        if case .edit(let album) = self { album } else { nil }
    }
}

/// Create or edit an emoji album: one emoji, one short name. Creating also makes the album in Photos.
struct AlbumEditor: View {
    let editing: ShelfAlbum?
    /// Called with the new shelf id after a create, so the swipe screen can select it.
    var onCreated: (String) -> Void = { _ in }
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var emojiText = ""
    @State private var nameText = ""
    @State private var isSaving = false
    @State private var error: String?

    private var emoji: String? { AlbumInput.emoji(from: emojiText) }
    private var name: String? { AlbumInput.name(from: nameText) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                EmojiField(text: $emojiText, focusOnAppear: editing == nil)
                    .frame(width: 112, height: 112)
                    .background(emoji == nil ? AnyShapeStyle(Theme.b100) : AnyShapeStyle(Color.white), in: Circle())
                    .overlay {
                        if emoji == nil {
                            Circle().strokeBorder(Theme.b500.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                                .allowsHitTesting(false)
                        }
                    }
                    .shadow(color: Theme.ink.opacity(emoji == nil ? 0 : 0.1), radius: 14, y: 6)
                    .scaleEffect(emoji == nil ? 1 : 1.04)
                    .animation(.spring(duration: 0.35, bounce: 0.45), value: emoji)
                    .sensoryFeedback(.selection, trigger: emoji)
                // Foodie's input: a soft grey pill, and a round arrow that appears inside it once it can save.
                HStack(spacing: 10) {
                    Image(systemName: "character.cursor.ibeam").foregroundStyle(Theme.dim)
                    TextField("Name", text: $nameText)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(Theme.ink)
                        .submitLabel(.done)
                        .onSubmit(save)
                    if emoji != nil && name != nil {
                        Button(action: save) {
                            Group {
                                if isSaving { ProgressView().tint(.white) } else { Image(systemName: "arrow.right").font(.headline.weight(.bold)) }
                            }
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(Theme.cta, in: Circle())
                            .shadow(color: Theme.b500.opacity(0.4), radius: 8, y: 4)
                        }
                        .buttonStyle(PressStyle())
                        .transition(.scale(scale: 0.4).combined(with: .opacity))
                        .accessibilityLabel(editing == nil ? "Create" : "Save")
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 6)
                .frame(height: 56)
                .background(Theme.fill, in: Capsule())
                .padding(.horizontal, 8)
                if let emoji, let name {
                    Text("\(emoji) \(name) in Photos")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(Theme.dim)
                        .transition(.opacity)
                }
                if let error {
                    Text(error).font(.footnote).foregroundStyle(Theme.delete).multilineTextAlignment(.center)
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 24)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .animation(.spring(duration: 0.35, bounce: 0.3), value: emoji != nil && name != nil)
            .background(Theme.page.ignoresSafeArea())
            .navigationTitle(editing == nil ? "New album" : "Edit album")
            .inlineTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(editing == nil ? "Create" : "Save", action: save)
                        .disabled(emoji == nil || name == nil || isSaving)
                }
            }
        }
        .presentationDetents([.medium])
        .onAppear {
            emojiText = editing?.emoji ?? ""
            nameText = editing?.name ?? ""
        }
    }

    private func save() {
        guard let emoji, let name, !isSaving else { return }
        isSaving = true
        Task {
            do {
                if let editing {
                    try await model.editShelfAlbum(editing.id, emoji: emoji, name: name)
                } else {
                    let id = try await model.createShelfAlbum(emoji: emoji, name: name)
                    onCreated(id)
                }
                Haptics.success(model.hapticsEnabled)
                dismiss()
            } catch {
                Haptics.warning(model.hapticsEnabled)
                self.error = "Photos didn't allow that. Give Photo Swipe full photo access in Settings."
                isSaving = false
            }
        }
    }
}

#if canImport(UIKit)
import UIKit

/// A text field that opens straight on the emoji keyboard and keeps only one emoji.
struct EmojiField: UIViewRepresentable {
    @Binding var text: String
    var focusOnAppear = false

    final class Field: UITextField {
        override var textInputContextIdentifier: String? { "" }
        override var textInputMode: UITextInputMode? {
            UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" } ?? super.textInputMode
        }
    }

    func makeUIView(context: Context) -> Field {
        let field = Field()
        field.font = .systemFont(ofSize: 54)
        field.textAlignment = .center
        field.tintColor = .clear
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        field.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .editingChanged)
        if focusOnAppear { DispatchQueue.main.async { field.becomeFirstResponder() } }
        return field
    }

    func updateUIView(_ field: Field, context: Context) {
        if field.text != text { field.text = text }
    }

    func makeCoordinator() -> Coordinator { Coordinator(text: $text) }

    final class Coordinator: NSObject {
        let text: Binding<String>
        init(text: Binding<String>) { self.text = text }

        @objc func changed(_ field: UITextField) {
            let picked = AlbumInput.emoji(from: field.text ?? "") ?? ""
            field.text = picked
            text.wrappedValue = picked
        }
    }
}
#else
/// Mac stand-in so the package type-checks. The product is iPhone only.
struct EmojiField: View {
    @Binding var text: String
    var focusOnAppear = false

    var body: some View {
        TextField("🙂", text: $text).font(.system(size: 54)).multilineTextAlignment(.center)
    }
}
#endif
