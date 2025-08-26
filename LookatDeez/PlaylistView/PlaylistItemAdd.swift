//
//  PlaylistItemAdd.swift
//  LookatDeez
//

import SwiftUI
import SwiftData

public struct PlaylistItemAdd: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    public let playlistId: UUID
    public let itemId: UUID?          // <-- nil = add, non-nil = edit

    @State private var playlist: Playlist?
    @State private var item: PlaylistItem?   // <-- loaded when editing
    @State private var label: String = ""
    @State private var urlString: String = ""
    @State private var loadError: String?
    @State private var confirmDelete = false

    public init(playlistId: UUID, itemId: UUID? = nil) {
        self.playlistId = playlistId
        self.itemId = itemId
    }

    private var isEditing: Bool { itemId != nil }

    public var body: some View {
        Group {
            if let _ = playlist {
                Form {
                    Section(header: Text("Details")) {
                        TextField("Title", text: $label)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)

                        TextField("https://example.com/…", text: $urlString)
                            .keyboardType(.URL)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .submitLabel(.done)
                            .onSubmit(saveIfValid)
                    }

                    if isEditing {
                        Section {
                            Button(role: .destructive) {
                                confirmDelete = true
                            } label: {
                                Text("Delete Item")
                            }
                        }
                    }
                }
                .navigationTitle(isEditing ? "Edit Item" : "Add Item")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save", action: saveIfValid)
                            .disabled(!isValid)
                    }
                }
                .alert("Delete this item?", isPresented: $confirmDelete) {
                    Button("Delete", role: .destructive) { deleteItem() }
                    Button("Cancel", role: .cancel) {}
                }

            } else if let loadError {
                VStack(spacing: 12) {
                    Text("Couldn’t load playlist")
                        .font(.headline)
                    Text(loadError).font(.caption).foregroundStyle(.secondary)
                }
                .padding()
            } else {
                ProgressView().task { await load() }
            }
        }
        .onAppear { Task { await load() } }
    }

    // MARK: - Validation

    private var isValid: Bool {
        sanitizedURL(from: urlString) != nil && !label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && playlist != nil
    }

    private func sanitizedURL(from raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed), url.scheme != nil { return url }
        return URL(string: "https://\(trimmed)")
    }

    // MARK: - Data ops

    private func load() async {
        do {
            // Load playlist
            let pdesc = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == playlistId })
            self.playlist = try context.fetch(pdesc).first
            if self.playlist == nil {
                self.loadError = "No playlist with id \(playlistId)"
                return
            }

            // If editing, load the item and prefill
            if let itemId {
                let idesc = FetchDescriptor<PlaylistItem>(predicate: #Predicate { $0.id == itemId })
                if let found = try context.fetch(idesc).first {
                    self.item = found
                    self.label = found.label
                    self.urlString = found.videoURL.absoluteString
                } else {
                    self.loadError = "No item with id \(itemId)"
                }
            }
        } catch {
            self.loadError = error.localizedDescription
        }
    }

    private func saveIfValid() {
        guard let playlist, let url = sanitizedURL(from: urlString), isValid else { return }

        let trimmedLabel = label.trimmingCharacters(in: .whitespacesAndNewlines)

        do {
            if let item {
                // EDIT EXISTING
                item.label = trimmedLabel
                item.videoURL = url
                item.playlist?.updatedAt = .now
            } else {
                // ADD NEW
                let nextIndex = (playlist.items.map(\.orderIndex).max() ?? -1) + 1
                let newItem = PlaylistItem(
                    label: trimmedLabel,
                    videoURL: url,
                    orderIndex: nextIndex,
                    playlist: playlist
                )
                playlist.items.append(newItem)
                playlist.updatedAt = .now
            }

            try context.save()
            // Optional: if you maintain an external index (for Share/Widget), call it here.
            // writePlaylistIndex(context: context)
            dismiss()

        } catch {
            print("Failed to save item:", error)
        }
    }

    private func deleteItem() {
        guard let playlist, let item else { return }
        do {
            context.delete(item)
            try context.save()

            // Renumber orderIndex to keep it dense after deletion
            let sorted = playlist.items.sorted { $0.orderIndex < $1.orderIndex }
            for (i, it) in sorted.enumerated() { it.orderIndex = i }
            playlist.updatedAt = .now
            try context.save()
            // writePlaylistIndex(context: context)
            dismiss()
        } catch {
            print("Failed to delete item:", error)
        }
    }
}

#Preview {
    // Preview with an on-disk container; seeds a sample playlist + item.
    do {
        let container = try ModelContainer(for: Playlist.self, PlaylistItem.self)
        let ctx = container.mainContext

        // Seed playlist & items
        let p: Playlist
        if let existing = try ctx.fetch(FetchDescriptor<Playlist>()).first {
            p = existing
        } else {
            let np = Playlist(title: "Preview List")
            let u = URL(string: "https://example.com/one")!
            let it = PlaylistItem(label: "Example", videoURL: u, orderIndex: 0, playlist: np)
            np.items.append(it)
            ctx.insert(np)
            try ctx.save()
            p = np
        }

        // Show ADD
        return NavigationStack {
            PlaylistItemAdd(playlistId: p.id)
        }
        .modelContainer(container)

    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
