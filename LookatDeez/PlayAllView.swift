// PlayAllView.swift
import SwiftUI
import SwiftData

struct PlayAllView: View {
    private let items: [PlaylistItem]
    @State private var currentIndex: Int
    @Environment(\.dismiss) private var dismiss

    // Optional hook if you want to persist "watched"
    var onMarkWatched: ((PlaylistItem) -> Void)?

    // Start at a given index (defaults to 0)
    init(items: [PlaylistItem], startIndex: Int = 0, onMarkWatched: ((PlaylistItem) -> Void)? = nil) {
        self.items = items.sorted { $0.orderIndex < $1.orderIndex }
        self._currentIndex = State(initialValue: min(max(0, startIndex), max(0, self.items.count - 1)))
        self.onMarkWatched = onMarkWatched
    }

    init(playlist: Playlist, startIndex: Int = 0, onMarkWatched: ((PlaylistItem) -> Void)? = nil) {
        self.init(items: playlist.items, startIndex: startIndex, onMarkWatched: onMarkWatched)
    }

    var body: some View {
        VStack(spacing: 0) {
            // SAFARI lives in the flexible top area (no overlay)
            TabView(selection: $currentIndex) {
                ForEach(items.indices, id: \.self) { i in
                    SafariView(url: items[i].videoURL)   // no ignoresSafeArea()
                        .tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))

            // Your own bottom toolbar — distinct surface, no overlap
            HStack(spacing: 16) {
                // Close (optional)
                Button(role: .cancel) { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .imageScale(.large)
                }

                Spacer()

                Button { step(-1) } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .imageScale(.large)
                }
                .disabled(currentIndex == 0)

                Text("\(currentIndex + 1) / \(items.count)")
                    .font(.subheadline)
                    .monospacedDigit()
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())

                Button { step(+1) } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .imageScale(.large)
                }
                .disabled(currentIndex >= items.count - 1)

                Spacer()

                Button {
                    if let item = items[safe: currentIndex] {
                        onMarkWatched?(item)
                    }
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                }
                .accessibilityLabel("Mark as watched")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.regularMaterial)
            .overlay(Divider(), alignment: .top)
        }
        .tint(.primary)
        .background(Color(.systemBackground)) // keeps transitions clean
    }

    private func step(_ delta: Int) {
        guard !items.isEmpty else { return }
        currentIndex = min(max(0, currentIndex + delta), items.count - 1)
    }
}

// Safety subscript so we don't crash when array is empty/animating
private extension Array {
    subscript(safe i: Index) -> Element? {
        indices.contains(i) ? self[i] : nil
    }
}
