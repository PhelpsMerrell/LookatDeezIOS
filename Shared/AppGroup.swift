//
//  AppGroup.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/26/25.
//

import Foundation

enum AppGroup {
    // 1) REPLACE THIS with your real App Group ID exactly as shown in Capabilities
    static let id = "group.com.yourco.lookatdeez"

    // 2) Shared container root
    static var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: id) else {
            fatalError("App Group not configured correctly: \(id)")
        }
        return url
    }

    // 3) Paths we use
    static var playlistsIndexURL: URL {
        containerURL.appendingPathComponent("playlists_index.json")
    }
    static var inboxFolderURL: URL {
        containerURL.appendingPathComponent("Inbox", isDirectory: true)
    }
    static var queueURL: URL {
        inboxFolderURL.appendingPathComponent("queue.json")
    }

    // 4) Ensure shared folders exist
    static func ensureFolders() {
        try? FileManager.default.createDirectory(at: inboxFolderURL, withIntermediateDirectories: true)
    }
}
