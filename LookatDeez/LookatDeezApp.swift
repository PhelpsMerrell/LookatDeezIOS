// LookatDeezApp.swift
import SwiftUI
import SwiftData

@main
struct LookatDeezApp: App {
    // Build a container we can access for mainContext
    let container: ModelContainer = {
        do {
            return try ModelContainer(for: Playlist.self, PlaylistItem.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
            .modelContainer(container)
            .tint(.primary)   // system adaptive: black/white depending on background// attach the container to the root view
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                // Import any items queued by the Share Extension
                processInbox(context: container.mainContext)
                // Keep the extension's playlist picker list fresh
                writePlaylistIndex(context: container.mainContext)
            }
        }
    }
}
