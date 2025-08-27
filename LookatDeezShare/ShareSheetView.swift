import SwiftUI
import UniformTypeIdentifiers
import UIKit   // needed for NSExtensionContext

struct ShareSheetView: View {
    weak var extensionContext: NSExtensionContext?
    @State private var sharedURL: URL?
    @State private var label: String = ""
    @State private var playlists: [PlaylistIndexEntry] = []
    @State private var selectedId: UUID?

    private var canSave: Bool { sharedURL != nil && selectedId != nil }

    var body: some View {
        // Provide R.sm/md/lg locally for the extension
        ConcentricLayout { _, R in
            NavigationStack {
                Form {
                    Section("Link") {
                        Text(sharedURL?.absoluteString ?? "—")
                            .font(.footnote)
                            .textSelection(.enabled)
                    }
                    Section("Title (optional)") {
                        TextField("Title", text: $label)
                            .textInputAutocapitalization(.words)
                    }
                    Section("Playlist") {
                        if playlists.isEmpty {
                            Text("No playlists found. Create one in LookatDeez.")
                                .foregroundStyle(.secondary)
                        } else {
                            Picker("Add to", selection: $selectedId) {
                                ForEach(playlists) { p in
                                    Text(p.title).tag(Optional.some(p.id))
                                }
                            }
                        }
                    }
                }
                .navigationTitle("Add to LookatDeez")
                .toolbar {
                    // Keep Cancel up top (system placement)
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { complete(cancel: true) }
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    HStack {
                        Spacer()
                        // Bottom-right Save pill using your concentric component
                        ConcentricPillButton(systemName: "square.and.arrow.down.on.square", radius: R.sm) {
                            save()
                        }
                        .disabled(!canSave)
                        .opacity(canSave ? 1.0 : 0.5)
                        .accessibilityLabel("Save to selected playlist")
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .background(.regularMaterial)
                    .overlay(Divider(), alignment: .top)
                }
                .task { await loadInputs() }
            }
        }
    }

    // MARK: - Load inputs

    private func loadInputs() async {
        AppGroup.ensureFolders()
        // Read the first URL from the extension's items
        if let ctx = extensionContext {
            self.sharedURL = await firstURL(from: ctx)
        }
        // Load playlist index provided by the host app
        if let data = try? Data(contentsOf: AppGroup.playlistsIndexURL),
           let index = try? JSONDecoder().decode([PlaylistIndexEntry].self, from: data) {
            self.playlists = index
            if selectedId == nil { selectedId = index.first?.id }
        }
    }

    private func firstURL(from context: NSExtensionContext) async -> URL? {
        for item in context.inputItems.compactMap({ $0 as? NSExtensionItem }) {
            for provider in item.attachments ?? [] {
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    return await withCheckedContinuation { cont in
                        provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { obj, _ in
                            let url = (obj as? URL) ?? (obj as? NSURL) as URL?
                            cont.resume(returning: url)
                        }
                    }
                }
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    let text: String? = await withCheckedContinuation { cont in
                        provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { obj, _ in
                            cont.resume(returning: obj as? String)
                        }
                    }
                    if let t = text, let url = URL(string: t.trimmingCharacters(in: .whitespacesAndNewlines)) {
                        return url
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Save to inbox

    private func save() {
        guard let url = sharedURL, let pid = selectedId else { return }
        let entry = InboxItem(
            type: "addItem",
            playlistId: pid,
            label: label.trimmingCharacters(in: .whitespacesAndNewlines),
            url: url.absoluteString,
            date: Date()
        )
        do {
            var arr: [InboxItem] = []
            if let data = try? Data(contentsOf: AppGroup.queueURL) {
                arr = (try? JSONDecoder().decode([InboxItem].self, from: data)) ?? []
            }
            arr.append(entry)
            let data = try JSONEncoder().encode(arr)
            try data.write(to: AppGroup.queueURL, options: .atomic)
            complete(cancel: false)
        } catch {
            // If anything fails, still complete so user isn't stuck
            complete(cancel: false)
        }
    }

    private func complete(cancel: Bool) {
        if cancel {
            extensionContext?.cancelRequest(withError: NSError(domain: "LookatDeez", code: 0))
        } else {
            extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
    }
}
