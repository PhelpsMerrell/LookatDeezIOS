// PlaylistMenu.swift
import SwiftUI
import SwiftData

struct PlaylistMenu: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Playlist.updatedAt, order: .reverse) private var playlists: [Playlist]

    var body: some View {
        Group {
            if playlists.isEmpty {
                ContentUnavailableView(
                    "No Playlists Yet",
                    systemImage: "music.note.list",
                    description: Text("Tap “New Playlist” to create your first list.")
                )
            } else {
                List {
                    ForEach(playlists) { playlist in
                        NavigationLink {
                            PlaylistEditor(playlistId: playlist.id)
                        } label: {
                            PlaylistCard(playlist: playlist)
                                .contentShape(Rectangle()) // better tap target
                        }
                    }
                    .onDelete(perform: deletePlaylists)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.clear)
                .background(Color.clear)
            }
        }
        .navigationTitle("Playlists")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink("New Playlist") {
                    PlaylistAdd()
                        .navigationTitle("Create New Playlist")
                }
            }
        }
    }

    private func deletePlaylists(_ offsets: IndexSet) {
        for i in offsets {
            context.delete(playlists[i])
        }
        do {
            try context.save()
            // NEW: keep Share Extension picker in sync
            writePlaylistIndex(context: context)
        } catch {
            print("Delete failed:", error)
        }
    }
}

#Preview {
    // On-disk store preview; seeds data if empty
    do {
        let container = try ModelContainer(for: Playlist.self, PlaylistItem.self)
        let ctx = container.mainContext

        var lists = try ctx.fetch(FetchDescriptor<Playlist>())
        if lists.isEmpty {
            let p1 = Playlist(title: "My Shorts")
            p1.items.append(PlaylistItem(label: "Cool vid",
                                         videoURL: URL(string: "https://example.com/a")!,
                                         orderIndex: 0,
                                         playlist: p1))
            let p2 = Playlist(title: "Music Vids")
            p2.items.append(PlaylistItem(label: "Track 1",
                                         videoURL: URL(string: "https://example.com/b")!,
                                         orderIndex: 0,
                                         playlist: p2))
            ctx.insert(p1); ctx.insert(p2)
            try ctx.save()
            lists = [p1, p2]
        }

        return NavigationStack { PlaylistMenu() }
            .modelContainer(container)

    } catch {
        return NavigationStack { Text("Preview error: \(error.localizedDescription)") }
    }
}
