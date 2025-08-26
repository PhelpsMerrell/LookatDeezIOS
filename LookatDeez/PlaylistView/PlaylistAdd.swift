//
//  PlaylistAdd.swift
//  LookatDeez
//

import SwiftUI
import SwiftData

public struct PlaylistAdd: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title: String = ""

    public init() {}

    public var body: some View {
        Form {
            Section(header: Text("Details")) {
                TextField("Playlist Name", text: $title)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .onSubmit(saveIfValid)
            }
        }
        .navigationTitle("Create New Playlist")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save", action: saveIfValid)
                    .disabled(!isValid)
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

        let p = Playlist(title: title.trimmingCharacters(in: .whitespacesAndNewlines))
        context.insert(p)

        do {
            try context.save()
            // 🔑 NEW: refresh playlist index so Share Extension can see it
            writePlaylistIndex(context: context)

            dismiss()
        } catch {
            // In a real app you might surface an alert
            print("Failed to save playlist:", error)
        }
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
