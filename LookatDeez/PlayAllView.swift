//
//  PlayAllView.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/25/25.
//

import SwiftUI
import SwiftData

struct PlayAllView: View {
    // Accept either a playlist or pre-sorted items. Use whichever init you prefer.
    private let items: [PlaylistItem]

    @State private var currentIndex: Int = 0
    @Environment(\.dismiss) private var dismiss

    init(items: [PlaylistItem]) {
        // Ensure stable order by orderIndex
        self.items = items.sorted { $0.orderIndex < $1.orderIndex }
    }

    init(playlist: Playlist) {
        self.init(items: playlist.items)
    }

    var body: some View {
        ZStack {
            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { i in
                    SafariView(url: items[i].videoURL)
                        .ignoresSafeArea()          // immersive
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Overlay controls
            VStack {
                // Top bar: title + close
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(items[safe: currentIndex]?.label ?? "")
                            .font(.headline)
                            .lineLimit(2)
                        if let host = items[safe: currentIndex]?.videoURL.host {
                            Text(host)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .imageScale(.large)
                            .padding(8)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)

                Spacer()

                // Bottom bar: prev/next + progress
                HStack(spacing: 16) {
                    Button {
                        withAnimation { step(-1) }
                    } label: {
                        Label("Prev", systemImage: "chevron.left.circle.fill")
                    }
                    .disabled(currentIndex == 0)

                    Text("\(currentIndex + 1) / \(items.count)")
                        .font(.subheadline)
                        .monospacedDigit()
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())

                    Button {
                        withAnimation { step(+1) }
                    } label: {
                        Label("Next", systemImage: "chevron.right.circle.fill")
                    }
                    .disabled(currentIndex >= items.count - 1)
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                .padding(.bottom, 20)
            }
            .tint(.primary)
        }
        .background(Color.black.opacity(0.001)) // keep gestures responsive
    }

    private func step(_ delta: Int) {
        let next = min(max(0, currentIndex + delta), items.count - 1)
        currentIndex = next
    }
}

// Safety subscript so we don't crash when array is empty/animating
private extension Array {
    subscript(safe i: Index) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
