//
//  PlaylistRow.swift
//  LookatDeez
//

import SwiftUI

struct PlaylistRow: View {
    var title: String
    var url: URL

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .lineLimit(2)

                Text(url.absoluteString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    PlaylistRow(
        title: "Latte Art in 60 Seconds",
        url: URL(string: "https://example.com/latte")!
    )
    .padding()
    
}
