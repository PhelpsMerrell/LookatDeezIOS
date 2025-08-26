// SharedCodables.swift  (target membership: LookatDeez + LookatDeezShare)
import Foundation

public struct PlaylistIndexEntry: Codable, Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }
}

public struct InboxItem: Codable {
    public let type: String           // e.g. "addItem"
    public let playlistId: UUID
    public let label: String
    public let url: String
    public let date: Date
    public init(type: String, playlistId: UUID, label: String, url: String, date: Date) {
        self.type = type
        self.playlistId = playlistId
        self.label = label
        self.url = url
        self.date = date
    }
}
