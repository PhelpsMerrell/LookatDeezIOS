//
//  PlaylistDTO.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/22/25.
//
import SwiftData
import Foundation
@Model
final class Playlist: Identifiable, Sendable, Equatable
{
    var id: UUID
    var title: String
    var owners: [String]
    var items : [PlaylistItem]
    var createdAt: Date?
    var updatedAt: Date?
    init(id: UUID = UUID(),
         title: String,
         owners: [String] = [],
         items: [PlaylistItem] = [],
         createdAt: Date = .now,
         updatedAt: Date = .now) {
        self.id = id
        self.title = title
        self.owners = owners
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
    }
}
