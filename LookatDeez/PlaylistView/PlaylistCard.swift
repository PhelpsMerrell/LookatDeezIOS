import SwiftUI

struct PlaylistCard: View {
    let playlist: Playlist

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)

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
        .background(.ultraThinMaterial, in: shape)                       // ← shows bg through
        .overlay(shape.stroke(.white.opacity(0.22), lineWidth: 0.6))     // subtle edge
        .clipShape(shape)
        .shadow(radius: 4, y: 2)
    }
}

#Preview {
    ZStack {
        // Demo background (color or image)
        LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        let p = Playlist(title: "My Favorite Shorts")
        PlaylistCard(playlist: p).padding()
    }
}
