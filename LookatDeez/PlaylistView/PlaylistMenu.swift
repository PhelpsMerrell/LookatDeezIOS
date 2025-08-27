import SwiftUI
import SwiftData

struct PlaylistMenu: View {
    @Environment(\.modelContext) private var context
    @Environment(\.concentricRadii) private var R

    @Query(sort: \Playlist.updatedAt, order: .reverse) private var playlists: [Playlist]
    @State private var addSheetShowing = false
    @State private var pushId: UUID? = nil   // for invisible NavigationLink
    @State private var bgColor: RGBAColor?   // NEW: background color state

    var body: some View {
        ZStack {
            // Background: chosen color (default system background)
            (bgColor?.color ?? Color(.systemBackground))
                .ignoresSafeArea()

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
                            ZStack {
                                PlaylistCard(playlist: playlist)
                                    .contentShape(RoundedRectangle(cornerRadius: R.md, style: .continuous))
                                    .onTapGesture { pushId = playlist.id }
                                    .overlay(
                                        Image(systemName: "chevron.right")
                                            .font(.headline)
                                            .foregroundStyle(.tertiary)
                                            .padding(.trailing, 12),
                                        alignment: .trailing
                                    )

                                NavigationLink(
                                    destination: PlaylistEditor(playlistId: playlist.id),
                                    tag: playlist.id,
                                    selection: $pushId
                                ) { EmptyView() }
                                .opacity(0)
                                .frame(width: 0, height: 0)
                                .accessibilityHidden(true)
                            }
                            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deletePlaylists)
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                }
            }
        }
        .navigationTitle("Playlists")
        .tint(.primary)
        .safeAreaInset(edge: .bottom) {
            HStack {
                // Left: Color picker icon only
                ColorPicker("", // empty string → no visible label
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
