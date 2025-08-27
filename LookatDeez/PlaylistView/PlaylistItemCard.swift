// PlaylistItemCard.swift
import SwiftUI

struct PlaylistItemCard: View {
    @Environment(\.concentricRadii) private var R
    let title: String
    let url: URL
    var watched: Bool = false            // NEW

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: R.sm, style: .continuous)

        ZStack(alignment: .topTrailing) {
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
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.stroke(.white.opacity(0.22), lineWidth: 0.6))
            .clipShape(shape)
            .shadow(radius: 3, y: 2)

            // Corner badge
            Image(systemName: watched ? "checkmark.circle.fill" : "checkmark.circle")
                .imageScale(.medium)
                .padding(8)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.25), lineWidth: 0.5))
                .padding(8)
                .opacity(watched ? 1.0 : 0.6)
                .accessibilityHidden(true)
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        VStack(spacing: 20) {
            PlaylistItemCard(
                title: "How to make boba simple syrup",
                url: URL(string: "https://youtu.be/dQw4w9WgXcQ")!,
                watched: false
            )
            PlaylistItemCard(
                title: "How to make boba simple syrup",
                url: URL(string: "https://youtu.be/dQw4w9WgXcQ")!,
                watched: true
            )
        }.padding()
    }
}
