import SwiftUI

struct PlaylistItemCard: View {
    @Environment(\.concentricRadii) private var R
    let title: String
    let url: URL

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
                .lineLimit(2)

            Text(url.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: R.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: R.sm, style: .continuous)
                .stroke(.white.opacity(0.22), lineWidth: 0.6)
        )
        .clipShape(RoundedRectangle(cornerRadius: R.sm, style: .continuous))
        .shadow(radius: 3, y: 2)
    }
}

#Preview {
    ZStack {
        Image("SampleBackground").resizable().scaledToFill().ignoresSafeArea()
        PlaylistItemCard(
            title: "How to make boba simple syrup",
            url: URL(string: "https://youtu.be/dQw4w9WgXcQ")!
        )
        .padding()
    }
}
