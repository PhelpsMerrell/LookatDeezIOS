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

    // Optionally set custom tokens; tweak baseHardwareRatio to adjust roundness globally
    private let concentricTokens = ConcentricTokens(
        grid: 8,
        baseHardwareRatio: 0.048
    )

    var body: some Scene {
        WindowGroup {
            ConcentricLayout { _, _ in
                NavigationStack {
                    ContentView()
                }
                .modelContainer(container)
                .tint(.primary)   // system adaptive tint
            }
            .environment(\.concentricTokens, concentricTokens) // inject tokens app-wide
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
