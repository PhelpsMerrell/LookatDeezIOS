import SwiftUI
import SwiftData

struct PlaylistMenu: View {
    @Environment(\.modelContext) private var context
    @Environment(\.concentricRadii) private var R

    @Query(sort: \Playlist.updatedAt, order: .reverse) private var playlists: [Playlist]
    @State private var addSheetShowing = false
    @State private var bgColor: RGBAColor?

    var body: some View {
        ZStack {
            (bgColor?.color ?? Color(.systemBackground)).ignoresSafeArea()

            Group {
                if playlists.isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No Playlists Yet",
                            systemImage: "music.note.list",
                            description: Text("Tap “New Playlist” to create your first list.")
                        )
                        ConcentricPillButton(systemName: "plus", radius: R.sm) {
                            addSheetShowing = true
                        }
                        .accessibilityLabel("New Playlist")
                    }
                    .padding(.top, 12)
                } else {
                    List {
                        ForEach(playlists) { playlist in
                            // Modern API: value-based NavigationLink (no chevron row chrome)
                            NavigationLink(value: playlist.id) {
                                PlaylistCard(playlist: playlist)
                                    .contentShape(RoundedRectangle(cornerRadius: R.md, style: .continuous))
                                    
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    // Destination lives here so ContentView doesn't need changes
                    .navigationDestination(for: UUID.self) { id in
                        PlaylistEditor(playlistId: id)
                    }
                }
            }
        }
        .navigationTitle("Playlists")
        .tint(.primary)
        .safeAreaInset(edge: .bottom) {
            HStack {
                // Left: Color picker icon only
                ColorPicker("",
                    selection: Binding(
                        get: { bgColor?.color ?? .blue },
                        set: { bgColor = RGBAColor($0) }
                    ),
                    supportsOpacity: true
                )
                .labelsHidden()

                Spacer()

                // Right: add playlist pill (icon only)
                ConcentricPillButton(systemName: "plus", radius: R.sm) {
                    addSheetShowing = true
                }
                .accessibilityLabel("New Playlist")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .overlay(Divider(), alignment: .top)
        }
        .sheet(isPresented: $addSheetShowing) {
            ConcentricModalContainer(radius: R.lg) {
                PlaylistAdd()
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    private func deletePlaylists(_ offsets: IndexSet) {
        for i in offsets { context.delete(playlists[i]) }
        do {
            try context.save()
            writePlaylistIndex(context: context)
        } catch {
            print("Delete failed:", error)
        }
    }
}

#Preview {
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

        return ConcentricLayout { _, _ in
            NavigationStack { PlaylistMenu() }
                .modelContainer(container)
        }
    } catch {
        return NavigationStack { Text("Preview error: \(error.localizedDescription)") }
    }
}
