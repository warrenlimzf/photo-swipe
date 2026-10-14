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
            VStack(spacing: 22) {
                EmojiField(text: $emojiText, focusOnAppear: editing == nil)
                    .frame(width: 104, height: 104)
                    .background(Theme.card, in: Circle())
                    .overlay { Circle().strokeBorder(Theme.hairline) }
                Text(emoji == nil ? "Tap the circle, pick an emoji" : "Emoji").eyebrow()
                TextField("Name, e.g. Golf", text: $nameText)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.ink)
                    .submitLabel(.done)
                    .onSubmit(save)
                    .padding(.vertical, 12)
                    .overlay(alignment: .bottom) { Rectangle().fill(Theme.hairline).frame(height: 1) }
                    .padding(.horizontal, 32)
                if let emoji, let name {
                    Text("Album in Photos: \(emoji) \(name)")
                        .font(.footnote)
                        .foregroundStyle(Theme.muted)
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
            .animation(.easeOut(duration: 0.2), value: emoji != nil && name != nil)
            .background(Theme.canvas.ignoresSafeArea())
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
