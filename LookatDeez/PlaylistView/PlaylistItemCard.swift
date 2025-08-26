//
//  PlaylistItemCard.swift
//  LookatDeez
//

import SwiftUI

struct PlaylistItemCard: View {
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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.tertiarySystemBackground))
        )
    }
}

#Preview {
    PlaylistItemCard(
        title: "How to make boba simple syrup",
        url: URL(string: "https://youtu.be/dQw4w9WgXcQ")!
    )
    .padding()

}
