import SwiftUI

struct PlaylistBackgroundView: View {
    let kind: PlaylistBackgroundKind
    let color: RGBAColor?
    let imageData: Data?

    var body: some View {
        Group {
            switch kind {
            case .none:
                Color(.systemBackground)

            case .color:
                (color?.color ?? Color(.systemBackground))

            case .photo:
                GeometryReader { geo in
                    if let data = imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()                  // ← never bleed
                    } else {
                        Color(.systemBackground)
                    }
                }
            }
        }
        .ignoresSafeArea()            // ← background only
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
