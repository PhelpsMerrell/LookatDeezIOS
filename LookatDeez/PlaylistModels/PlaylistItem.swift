//
//  PlaylistItemDTO.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/22/25.
//
import SwiftData
import Foundation
@Model
final class PlaylistItem: Identifiable, Equatable {
    @Attribute(.unique) var id: UUID
    var label: String
    var videoURL: URL
    var orderIndex: Int
    var playlist: Playlist?
    init(id: UUID = UUID(),
         label: String,
         videoURL: URL,
         orderIndex: Int,
         playlist: Playlist? = nil
         ) {
        self.id = id
        self.label = label
        self.videoURL = videoURL
        self.orderIndex = orderIndex
        self.playlist = playlist
     
    }
  
}
