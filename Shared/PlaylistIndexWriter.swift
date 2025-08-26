//
//  PlaylistIndexWriter.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/26/25.
//

import Foundation
import SwiftData



func writePlaylistIndex(context: ModelContext) {
    AppGroup.ensureFolders()
    do {
        let lists = try context.fetch(FetchDescriptor<Playlist>())
        let entries = lists.map { PlaylistIndexEntry(id: $0.id, title: $0.title) }
        let data = try JSONEncoder().encode(entries)
        try data.write(to: AppGroup.playlistsIndexURL, options: .atomic)
    } catch {
        print("Failed to write playlist index:", error)
    }
}
