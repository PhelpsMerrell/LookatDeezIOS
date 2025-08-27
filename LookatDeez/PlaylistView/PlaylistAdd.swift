//
//  PlaylistAdd.swift
//  LookatDeez
//

import SwiftUI
import SwiftData

public struct PlaylistAdd: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    private let playlist: Playlist?
    @State private var title: String = ""
    @State private var bgKind: PlaylistBackgroundKind = .none
    @State private var bgColor: RGBAColor? = nil
    @State private var bgImageData: Data? = nil


     init(playlist: Playlist? = nil) {
            self.playlist = playlist
            if let p = playlist {
                _title = State(initialValue: p.title)
                _bgKind = State(initialValue: p.bgKind)
                _bgColor = State(initialValue: p.bgColor)
                _bgImageData = State(initialValue: p.bgImageData)
            }
        }

    public var body: some View {
        VStack(spacing: 0) {
            // LIVE PREVIEW (uses the in-progress picks)
            ZStack {
                PlaylistBackgroundView(kind: bgKind, color: bgColor, imageData: bgImageData)
                    .frame(height: 160)
                     // optional

                Text(title.isEmpty ? "Playlist Preview" : title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .shadow(radius: 2)
            }

            Form {
                Section(header: Text("Details")) {
                    TextField("Playlist Name", text: $title)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(saveIfValid)
                }

                PlaylistBackgroundPicker(kind: $bgKind, color: $bgColor, imageData: $bgImageData)
            }
        }
        .navigationTitle(playlist == nil ? "Create New Playlist" : "Edit Playlist")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: saveIfValid).disabled(!isValid)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
                } else {
                    // New
                    let p = Playlist(title: trimmed)
                    p.bgKind = bgKind
                    p.bgColor = bgColor
                    p.bgImageData = bgImageData
                    context.insert(p)
                }
        do {
            try context.save()
            writePlaylistIndex(context: context)
            dismiss()
        } catch { print("Failed to save playlist:", error) }
    }
}

#Preview {
    // Preview with on-disk container (not inMemory)
    do {
        let container = try ModelContainer(for: Playlist.self, PlaylistItem.self)
        return NavigationStack {
            PlaylistAdd()
        }
        .modelContainer(container)
    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
