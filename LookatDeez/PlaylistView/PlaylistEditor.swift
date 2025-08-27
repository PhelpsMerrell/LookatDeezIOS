import SwiftUI
import SwiftData

// 1) Add this at the top of the file (outside the View)
private enum EditorModal: Identifiable, Equatable {
    case player
    case addNewItem
    case addItem(UUID)          // selected item id
    case editPlaylist
    case confirmDeleteAll

    var id: String {
        switch self {
        case .player: return "player"
        case .addNewItem: return "addNewItem"
        case .addItem(let id): return "addItem-\(id)"
        case .editPlaylist: return "editPlaylist"
        case .confirmDeleteAll: return "confirmDeleteAll"
        }
    }
}

struct PlaylistEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.editMode) private var editMode
    @Environment(\.concentricRadii) private var R     // ← concentric radii

    let playlistId: UUID?
    @State private var playlist: Playlist?
    @State private var activeModal: EditorModal? = nil
    @State private var selectedItemId: UUID?

    // Stable sort
    private var sortedItems: [PlaylistItem] {
        guard let playlist else { return [] }
        return playlist.items.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        Group {
            if let playlist {
                // FOREGROUND CONTENT ONLY
                List {
                    Section("") {
                        ForEach(sortedItems) { item in
                            // Make the card be the row (no extra layer)
                            Button {
                                selectedItemId = item.id
                                activeModal = .addItem(item.id)
                            } label: {
                                PlaylistItemCard(title: item.label, url: item.videoURL)
                                    .contentShape(RoundedRectangle(cornerRadius: R.md, style: .continuous))
                            }
                            // Row chrome cleanup → no outer box, no separator, comfy insets
                            .listRowInsets(.init(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: deleteItems)
                        .onMove(perform: moveItems)
                    }
                }
                // Let background show through and keep rows in-bounds
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(
                    ZStack {
                        PlaylistBackgroundView(
                            kind: playlist.bgKind,
                            color: playlist.bgColor,
                            imageData: playlist.bgImageData
                        )
                        LinearGradient(
                            colors: [.black.opacity(0.28), .clear, .black.opacity(0.28)],
                            startPoint: .top, endPoint: .bottom
                        )
                        .ignoresSafeArea()
                    }
                )
                .contentMargins(.vertical, 8)
                .safeAreaPadding(.bottom, 84)   // space for bottom bar

                .navigationTitle(playlist.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.regularMaterial, for: .navigationBar)
                .toolbarBackgroundVisibility(.visible, for: .navigationBar)
                .tint(.primary)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        ConcentricPillButton(systemName: "pencil", radius: R.sm) {
                            activeModal = .editPlaylist
                        }
                        .accessibilityLabel("Edit playlist")
                    }
                }

                // BOTTOM BAR: + (left), Edit/Done or Delete All (center), Play (right)
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        // Left: add new item
                        ConcentricPillButton(systemName: "plus", radius: R.sm) {
                            activeModal = .addNewItem
                        }
                        .accessibilityLabel("New item")

                        Spacer()

                        // Middle: ALWAYS the edit-mode toggle
                        ConcentricPillButton(systemName: "slider.horizontal.3", radius: R.sm) {
                            withAnimation {
                                if editMode?.wrappedValue.isEditing == true {
                                    editMode?.wrappedValue = .inactive
                                } else {
                                    editMode?.wrappedValue = .active
                                }
                            }
                        }
                        .accessibilityLabel(editMode?.wrappedValue.isEditing == true ? "Done editing" : "Enter edit mode")

                        Spacer()

                        // Right: PLAY normally, TRASH when editing
                        if editMode?.wrappedValue.isEditing == true {
                            ConcentricPillButton(systemName: "trash", role: .destructive, radius: R.sm) {
                                activeModal = .confirmDeleteAll
                            }
                            .disabled(sortedItems.isEmpty)
                            .opacity(sortedItems.isEmpty ? 0.5 : 1.0)
                            .accessibilityLabel("Delete all items")
                        } else {
                            ConcentricPillButton(systemName: "play.fill", radius: R.sm) {
                                activeModal = .player
                            }
                            .disabled(sortedItems.isEmpty)
                            .opacity(sortedItems.isEmpty ? 0.5 : 1.0)
                            .accessibilityLabel("Play playlist")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.regularMaterial)
                    .overlay(Divider(), alignment: .top)
                    .tint(.primary)
                }

            } else {
                Text("Playlist ain't real").task { await loadPlaylist() }
            }
        }
        .onAppear { Task { await loadPlaylist() } }

        // Single modal switch
        .sheet(item: $activeModal) { modal in
            switch modal {
            case .player:
                PlayAllView(items: sortedItems).ignoresSafeArea()

            case .addItem(let iid):
                if let pid = playlist?.id {
                    PlaylistItemAdd(playlistId: pid, itemId: iid)
                } else {
                    Text("No playlist loaded")
                }

            case .addNewItem:
                if let pid = playlist?.id {
                    PlaylistItemAdd(playlistId: pid)
                } else {
                    Text("No playlist loaded")
                }

            case .editPlaylist:
                if let p = playlist {
                    ConcentricModalContainer(radius: R.lg) {
                        PlaylistAdd(playlist: p)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                } else {
                    Text("No playlist loaded")
                }

            case .confirmDeleteAll:
                ConcentricModalContainer(radius: R.lg) {
                    VStack(spacing: 16) {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.red)
                        Text("Delete all items?")
                            .font(.headline)
                        Text("This will permanently remove every item in this playlist.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        HStack {
                            Button("Cancel") {
                                activeModal = nil
                            }
                            .buttonStyle(.bordered)

                            Button(role: .destructive) {
                                deleteAllItems()
                                activeModal = nil
                                withAnimation { editMode?.wrappedValue = .inactive }
                            } label: {
                                Text("Delete All")
                                    .foregroundStyle(.red) // ensure legible red label
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .presentationDetents([.height(240), .medium])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Data ops
    private func loadPlaylist() async {
        guard let pid = playlistId else { return }
        do {
            let desc = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == pid })
            playlist = try context.fetch(desc).first
        } catch { print("Failed to fetch playlist:", error) }
    }

    private func deleteItems(_ offsets: IndexSet) {
        guard let playlist else { return }
        for index in offsets { context.delete(sortedItems[index]) }
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

    private func deleteAllItems() {
        guard let playlist else { return }
        for item in sortedItems { context.delete(item) }
        playlist.items.removeAll()
        playlist.updatedAt = .now
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

        return ConcentricLayout { _, _ in
            NavigationStack {
                PlaylistEditor(playlistId: p.id)
            }
            .modelContainer(container)
        }

    } catch {
        return NavigationStack { Text("Preview error: \(error.localizedDescription)") }
    }
}
