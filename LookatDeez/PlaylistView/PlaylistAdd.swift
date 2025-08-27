//
//  PlaylistAdd.swift
//  LookatDeez
//

import SwiftUI
import SwiftData

public struct PlaylistAdd: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.concentricRadii) private var R

    private let playlist: Playlist?
    // Live editing state
    @State private var title: String = ""
    @State private var bgKind: PlaylistBackgroundKind = .none
    @State private var bgColor: RGBAColor? = nil
    @State private var bgImageData: Data? = nil

    // Snapshot of originals for dirty-checking
    private let originalTitle: String
    private let originalKind: PlaylistBackgroundKind
    private let originalColor: RGBAColor?
    private let originalImageData: Data?

    @State private var showDiscardConfirm = false

    // MARK: - Init
    init(playlist: Playlist? = nil) {
        self.playlist = playlist

        // Initialize from model or defaults
        if let p = playlist {
            _title = State(initialValue: p.title)
            _bgKind = State(initialValue: p.bgKind)
            _bgColor = State(initialValue: p.bgColor)
            _bgImageData = State(initialValue: p.bgImageData)

            self.originalTitle = p.title
            self.originalKind = p.bgKind
            self.originalColor = p.bgColor
            self.originalImageData = p.bgImageData
        } else {
            self.originalTitle = ""
            self.originalKind = .none
            self.originalColor = nil
            self.originalImageData = nil
        }
    }

    // MARK: - Derived
    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var isDirty: Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let tChanged = trimmed != originalTitle
        let kChanged = bgKind != originalKind
        let cChanged = bgColor != originalColor
        let iChanged = bgImageData != originalImageData
        return tChanged || kChanged || cChanged || iChanged
    }

    // MARK: - Body
    public var body: some View {
        VStack(spacing: 0) {
            // LIVE PREVIEW (uses the in-progress picks)
            ZStack {
                PlaylistBackgroundView(kind: bgKind, color: bgColor, imageData: bgImageData)
                    .frame(height: 160)

                Text(title.isEmpty ? "Playlist Preview" : title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }

            Form {
                Section(header: Text("Details")) {
                    TextField("Playlist Name", text: $title)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)           // no auto-save on submit anymore
                }

                PlaylistBackgroundPicker(kind: $bgKind, color: $bgColor, imageData: $bgImageData)
            }
        }
        .navigationTitle(playlist == nil ? "Create New Playlist" : "Edit Playlist")
        .toolbar {
            // Keep the standard Cancel in the nav (works nicely with swipe-down)
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { handleCancel() }
            }
            // No top-right Save; we move that to the bottom bar
        }
        // Bottom bar with Cancel (left) and Save (right) — icon-only concentric pills
        .safeAreaInset(edge: .bottom) {
            HStack {
                // Left: Cancel pill
                ConcentricPillButton(systemName: "xmark", radius: R.sm) {
                    handleCancel()
                }
                .accessibilityLabel("Cancel")

                Spacer()

                // Right: Save pill
                ConcentricPillButton(systemName: "checkmark", radius: R.sm) {
                    saveIfValid()
                }
                .disabled(!isValid)
                .opacity(isValid ? 1.0 : 0.5)
                .accessibilityLabel("Save playlist")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .overlay(Divider(), alignment: .top)
        }
        .alert("Discard changes?", isPresented: $showDiscardConfirm) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes.")
        }
    }

    // MARK: - Actions
    private func handleCancel() {
        if isDirty {
            showDiscardConfirm = true
        } else {
            dismiss()
        }
    }

    private func saveIfValid() {
        guard isValid else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)

        if let p = playlist {
            // Editing existing
            p.title = trimmed
            p.bgKind = bgKind
            p.bgColor = bgColor
            p.bgImageData = bgImageData
            p.updatedAt = .now
        } else {
            // New
            let p = Playlist(title: trimmed)
            p.bgKind = bgKind
            p.bgColor = bgColor
            p.bgImageData = bgImageData
            p.updatedAt = .now
            context.insert(p)
        }

        do {
            try context.save()
            writePlaylistIndex(context: context)
            dismiss()
        } catch {
            print("Failed to save playlist:", error)
        }
    }
}

#Preview {
    // Preview with on-disk container (not inMemory)
    do {
        let container = try ModelContainer(for: Playlist.self, PlaylistItem.self)
        return ConcentricLayout { _, _ in
            NavigationStack {
                PlaylistAdd()
            }
            .modelContainer(container)
        }
    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
