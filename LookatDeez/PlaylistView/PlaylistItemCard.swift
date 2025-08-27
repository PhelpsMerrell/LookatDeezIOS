import SwiftUI

struct PlaylistItemCard: View {
    let title: String
    let url: URL

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)

        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline).lineLimit(2)
            Text(url.absoluteString).font(.caption).foregroundStyle(.secondary).lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: shape)                       // ← shows bg through
        .overlay(shape.stroke(.white.opacity(0.22), lineWidth: 0.6))
        .clipShape(shape)
        .shadow(radius: 3, y: 2)
    }
}

#Preview {
    ZStack {
        Image("SampleBackground").resizable().scaledToFill().ignoresSafeArea()
        PlaylistItemCard(title: "How to make boba simple syrup",
                         url: URL(string: "https://youtu.be/dQw4w9WgXcQ")!)
        .padding()
    }
}
