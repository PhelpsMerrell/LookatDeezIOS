import SwiftUI

struct PlaylistCard: View {
    @Environment(\.concentricRadii) private var R
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(playlist.title)
                .font(.title2).fontWeight(.semibold)
                .lineLimit(1).minimumScaleFactor(0.8)

            Text("\(playlist.items.count) item\(playlist.items.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: R.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: R.md, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 0.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: R.md, style: .continuous))
        .shadow(radius: 4, y: 2)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        let p = Playlist(title: "My Favorite Shorts")
        PlaylistCard(playlist: p).padding()
    }
}
