//
//  ContentView.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/20/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NavigationStack {
            PlaylistMenu()
                .navigationTitle("Playlist Menu")
        }.toolbarBackground(.regularMaterial, for: .navigationBar)
            .toolbarBackgroundVisibility(.visible, for: .navigationBar)
            .tint(.primary)
    }
}

#Preview {
    // Preview with an on-disk container (NOT inMemory).
    do {
        let container = try ModelContainer(for: Playlist.self, PlaylistItem.self)
        let ctx = container.mainContext

        // Seed example data if empty
        let existing = try ctx.fetch(FetchDescriptor<Playlist>())
        if existing.isEmpty {
            let p = Playlist(title: "Sample Playlist")
            let urls = [
                URL(string: "https://example.com/one")!,
                URL(string: "https://example.com/two")!,
                URL(string: "https://example.com/three")!
            ]
            for (i, u) in urls.enumerated() {
                let item = PlaylistItem(label: "Item \(i + 1)", videoURL: u, orderIndex: i, playlist: p)
                p.items.append(item)
            }
            ctx.insert(p)
            try ctx.save()
        }

        return ContentView()
            .modelContainer(container)

    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
