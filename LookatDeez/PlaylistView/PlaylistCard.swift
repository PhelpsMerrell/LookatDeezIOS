import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(playlist.title)
                .font(.title2).fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text("\(playlist.items.count) item\(playlist.items.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    // Simple preview object; no container required just to render the card.
    let p = Playlist(title: "My Favorite Shorts")
    p.items = [
        PlaylistItem(label: "Cool Vid", videoURL: URL(string: "https://example.com/a")!, orderIndex: 0, playlist: p),
        PlaylistItem(label: "Great Tip", videoURL: URL(string: "https://example.com/b")!, orderIndex: 1, playlist: p),
    ]
    return PlaylistCard(playlist: p)
        .padding()
}

