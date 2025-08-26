// PlaylistEditor.swift
import SwiftUI
import SwiftData

struct PlaylistEditor: View {
    @Environment(\.modelContext) private var context

    let playlistId: UUID?
    @State private var playlist: Playlist?
    @State private var showPlayer = false

    // Sorted view of items for stable UI + reordering
    private var sortedItems: [PlaylistItem] {
        guard let playlist else { return [] }
        return playlist.items.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        Group {
            if let playlist {
                List {
                    Section {
                        TextField("Playlist title", text: Binding(
                            get: { playlist.title },
                            set: {
                                playlist.title = $0
                                playlist.updatedAt = .now
                                save()
                                // NEW: title changed — refresh index
                                writePlaylistIndex(context: context)
                            }
                        ))                    }

                    Section("Items") {
                        ForEach(sortedItems) { item in
                            NavigationLink {
                                       PlaylistItemAdd(playlistId: playlist.id, itemId: item.id) // EDIT
                                   } label: {
                                       PlaylistItemCard(title: item.label, url: item.videoURL)
                                   }
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                }
                .navigationTitle("Edit Playlist")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        EditButton()

                        // Add new item
                        let pid = playlist.id
                        NavigationLink {
                            PlaylistItemAdd(playlistId: pid)
                                .navigationTitle("Create New Item")
                        } label: {
                            Label("New Item", systemImage: "plus")
                        }
                    }
                }
                // Floating play button in the bottom-right corner of THIS screen only
                .overlay(alignment: .bottomTrailing) {
                    PlayCornerButton(
                        enabled: !sortedItems.isEmpty,
                        action: { showPlayer = true }
                    )
                    .padding(.trailing, 16)
                    .padding(.bottom, 20)
                }
                // Present the swipeable Safari player for THIS playlist
                .sheet(isPresented: $showPlayer) {
                    PlayAllView(items: sortedItems)
                        .ignoresSafeArea()
                }
                
              
            } else {
                Text("Playlist ain't real")
                    .task { await loadPlaylist() }
            }
        }
        .onAppear { Task { await loadPlaylist() } }
    }

    // MARK: - Data ops

    private func loadPlaylist() async {
        guard let pid = playlistId else { return }
        do {
            let descriptor = FetchDescriptor<Playlist>(
                predicate: #Predicate { $0.id == pid }
            )
            playlist = try context.fetch(descriptor).first
        } catch {
            print("Failed to fetch playlist:", error)
        }
    }

    private func deleteItems(_ offsets: IndexSet) {
        guard let playlist else { return }
        for index in offsets {
            context.delete(sortedItems[index])
        }
        renumberOrderIndices()
        playlist.updatedAt = .now
        save()
    }

    private func moveItems(from source: IndexSet, to destination: Int) {
        guard playlist != nil else { return }
        var working = sortedItems
        working.move(fromOffsets: source, toOffset: destination)
        for (i, item) in working.enumerated() { item.orderIndex = i }
        playlist?.updatedAt = .now
        save()
    }

    private func renumberOrderIndices() {
        for (i, item) in sortedItems.enumerated() { item.orderIndex = i }
    }

    private func save() {
        do { try context.save() } catch { print("Save failed:", error) }
    }
}

#Preview {
    // Preview uses a real on-disk container here (not inMemory).
    // It seeds a sample playlist so the editor has something to show.
    do {
        let container = try ModelContainer(for: Playlist.self, PlaylistItem.self)
        let ctx = container.mainContext

        let p = Playlist(title: "Sample Playlist")
        let urls = [
            URL(string: "https://example.com/one")!,
            URL(string: "https://example.com/two")!,
            URL(string: "https://example.com/three")!
        ]
        for (i, u) in urls.enumerated() {
            let item = PlaylistItem(label: "Item \(i + 1)", videoURL: u, orderIndex: i, playlist: p)
            p.items.append(item)
        }
        ctx.insert(p)
        try ctx.save()

        return NavigationStack {
            PlaylistEditor(playlistId: p.id)
        }
        .modelContainer(container)

    } catch {
        // Fallback preview if container creation fails
        return NavigationStack { Text("Preview error: \(error.localizedDescription)") }
    }
}

// Inline “liquid glass” mini player just for this screen
private struct MiniPlayInline: View {
    let title: String
    let host: String
    let enabled: Bool
    var onPlay: () -> Void
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.circle.fill")
                .imageScale(.large)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.callout).bold()
                    .lineLimit(1)
                Text(host)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button(action: onPlay) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .imageScale(.medium)
                    .padding(8)
            }
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)

            Button(action: onClear) {
                Image(systemName: "xmark")
                    .imageScale(.medium)
                    .padding(8)
            }
            .disabled(!enabled)
            .opacity(enabled ? 1 : 0.5)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule()) // liquid glass
        .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
        .shadow(radius: 4, y: 2)
        .opacity(enabled ? 1 : 0.7)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Play playlist")
        .accessibilityHint(enabled ? "Opens player" : "No items in this playlist")
    }
}
private struct PlayCornerButton: View {
    let enabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text("Play").font(.callout).bold()
                Image(systemName: "play.fill")
            }
            
                .font(.title2)                 // small, but tappable
                .padding(14)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(.white.opacity(0.25), lineWidth: 0.5))
                .shadow(radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1.0 : 0.5)
        .accessibilityLabel("Play playlist")
        .accessibilityHint(enabled ? "Opens the web viewer" : "No items to play")
    }
}
