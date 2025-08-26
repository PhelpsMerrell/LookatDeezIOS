import Foundation
import SwiftData




func processInbox(context: ModelContext) {
    AppGroup.ensureFolders()
    let url = AppGroup.queueURL

    guard let data = try? Data(contentsOf: url),
          let items = try? JSONDecoder().decode([InboxItem].self, from: data),
          !items.isEmpty else {
        return
    }

    do {
        for entry in items {
            guard let link = URL(string: entry.url) else { continue }

            // Find playlist
            let desc = FetchDescriptor<Playlist>(predicate: #Predicate { $0.id == entry.playlistId })
            guard let p = try context.fetch(desc).first else { continue }

            // Next index
            let nextIndex = (p.items.map(\.orderIndex).max() ?? -1) + 1

            let item = PlaylistItem(
                label: entry.label,
                videoURL: link,
                orderIndex: nextIndex,
                playlist: p
            )
            p.items.append(item)
            p.updatedAt = .now
        }

        try context.save()

        // Clear the queue after processing
        try Data("[]".utf8).write(to: url, options: .atomic)

    } catch {
        print("Inbox import failed:", error)
    }
}
