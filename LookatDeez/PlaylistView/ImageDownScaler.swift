//
//  ImageDownScaler.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/26/25.
//

import UIKit

/// Downscale and JPEG-compress raw image data for background use.
///
/// - Parameters:
///   - data: original image data (from PhotosPicker)
///   - maxDimension: longest side after resize (pts, not px). 1400–2200 works well for full-screen backgrounds.
///   - maxFileBytes: final output size budget (e.g. 500–900 KB keeps things snappy).
///   - opaque: true if you don't need transparency (saves space, faster).
/// - Returns: optimized JPEG data, or nil if decoding fails.
func downscaleImageData(
    _ data: Data,
    maxDimension: CGFloat = 1800,
    maxFileBytes: Int = 700_000,
    opaque: Bool = true
) -> Data? {
    guard let original = UIImage(data: data) else { return nil }

    // Determine target size preserving aspect ratio
    let w = original.size.width
    let h = original.size.height
    guard w > 0, h > 0 else { return nil }

    let longest = max(w, h)
    let scale = min(1.0, maxDimension / longest)
    let targetSize = CGSize(width: floor(w * scale), height: floor(h * scale))

    // Render (this also fixes orientation)
    let format = UIGraphicsImageRendererFormat.default()
    format.opaque = opaque
    format.scale = 1 // render at 1x; we’re controlling absolute point size

    let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
    let resized = renderer.image { _ in
        original.draw(in: CGRect(origin: .zero, size: targetSize))
    }

    // Compress to fit size budget (iterative quality fallbacks)
    let qualities: [CGFloat] = [0.82, 0.72, 0.62, 0.52, 0.42, 0.35, 0.28]
    for q in qualities {
        if let jpeg = resized.jpegData(compressionQuality: q), jpeg.count <= maxFileBytes {
            return jpeg
        }
    }
    // If still too large, return the smallest we made
    return resized.jpegData(compressionQuality: qualities.last ?? 0.28)
}
