//
//  PlaylistDTO.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/22/25.
//
import SwiftData
import Foundation
import UIKit
import SwiftUICore

enum PlaylistBackgroundKind: String, Codable, CaseIterable, Identifiable {
    case none, color, photo
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none:  return "None"
        case .color: return "Color"
        case .photo: return "Photo"
        }
    }
}

/// Codable color wrapper so we can store a Color in SwiftData
struct RGBAColor: Codable, Hashable {
    var r: Double
    var g: Double
    var b: Double
    var a: Double
    
    init(_ c: Color) {
        // Resolve to sRGB components
        var rr: CGFloat = 0, gg: CGFloat = 0, bb: CGFloat = 0, aa: CGFloat = 0
        UIColor(c).getRed(&rr, green: &gg, blue: &bb, alpha: &aa)
        r = Double(rr); g = Double(gg); b = Double(bb); a = Double(aa)
    }
    var color: Color { Color(red: r, green: g, blue: b).opacity(a) }
}


@Model
final class Playlist: Identifiable, Equatable {
    // Identity & core fields
    var id: UUID
    var title: String
    var owners: [String]
    var items: [PlaylistItem]
    var createdAt: Date?
    var updatedAt: Date?

    // ---------- Appearance (SwiftData-safe storage) ----------

    // Store enum as a primitive
    private var bgKindRaw: String = PlaylistBackgroundKind.none.rawValue
    /// Public wrapper for background kind
    var bgKind: PlaylistBackgroundKind {
        get { PlaylistBackgroundKind(rawValue: bgKindRaw) ?? .none }
        set { bgKindRaw = newValue.rawValue }
    }

    // Store RGBAColor as Data (Codable)
    private var bgColorData: Data? = nil
    /// Public wrapper for background color
    var bgColor: RGBAColor? {
        get {
            guard let bgColorData else { return nil }
            return try? JSONDecoder().decode(RGBAColor.self, from: bgColorData)
        }
        set {
            bgColorData = try? JSONEncoder().encode(newValue)
        }
    }

    /// Background image bytes (kept out of main DB file)
    @Attribute(.externalStorage)
    var bgImageData: Data? = nil

    // ---------- Init ----------

    init(
        id: UUID = UUID(),
        title: String,
        owners: [String] = [],
        items: [PlaylistItem] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.owners = owners
        self.items = items
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // ---------- Equatable ----------

    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}
