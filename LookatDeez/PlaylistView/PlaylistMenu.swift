import SwiftUI
import SwiftData

struct PlaylistMenu: View {
    @Environment(\.modelContext) private var context
    @Environment(\.concentricRadii) private var R

    @Query(sort: \Playlist.updatedAt, order: .reverse) private var playlists: [Playlist]
    @State private var addSheetShowing = false

    // Persisted color (JSON-encoded RGBAColor)
    @AppStorage("playlistMenuBgColor_v1") private var bgColorData: Data = Data()
    @State private var bgColor: RGBAColor? = nil

    var body: some View {
        ZStack {
            (bgColor?.color ?? Color(.systemBackground)).ignoresSafeArea()

            Group {
                if playlists.isEmpty {
                    VStack(spacing: 16) {
                        ContentUnavailableView(
                            "No Playlists Yet",
                            systemImage: "music.note.list",
                            description: Text("Tap the '+' to create your first list.")
                        )
                    }
                    .padding(.top, 12)
                } else {
                    List {
                        ForEach(playlists) { playlist in
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
                // Left: Color picker icon only (persists)
                ColorPicker("",
                    selection: Binding(
                        get: { bgColor?.color ?? .blue },
                        set: { newColor in
                            bgColor = RGBAColor(newColor)
                        }
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
        // Load persisted color once
        .task { loadBgColor() }
        // Save whenever it changes
        .onChange(of: bgColor) { _, _ in saveBgColor() }
    }

    // MARK: - Persistence
    private func loadBgColor() {
        guard !bgColorData.isEmpty,
              let decoded = try? JSONDecoder().decode(RGBAColor.self, from: bgColorData) else {
            return
        }
        bgColor = decoded
    }

    private func saveBgColor() {
        if let c = bgColor, let data = try? JSONEncoder().encode(c) {
            bgColorData = data
        } else {
            bgColorData = Data()
        }
    }

    // MARK: - Data ops
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
