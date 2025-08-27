//
//  PlaylistBackgroundPicker.swift
//  LookatDeez
//
//  Created by Phelps Merrell on 8/26/25.
//

import SwiftUI
import PhotosUI

struct PlaylistBackgroundPicker: View {
    @Binding var kind: PlaylistBackgroundKind
    @Binding var color: RGBAColor?
    @Binding var imageData: Data?

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        Section("Background") {
            Picker("Background", selection: $kind) {
                ForEach(PlaylistBackgroundKind.allCases) { k in
                    Text(k.label).tag(k)
                }
            }
            .pickerStyle(.segmented)

            if kind == .color {
                ColorPicker("Pick a color",
                            selection: Binding(
                                get: { color?.color ?? .blue },
                                set: { color = RGBAColor($0) }
                            ),
                            supportsOpacity: true
                )
            }

            if kind == .photo {
                VStack(alignment: .leading, spacing: 8) {
                    PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                        Label(imageData == nil ? "Choose Photo" : "Change Photo",
                              systemImage: "photo")
                    }

                    if let data = imageData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 120)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.separator))
                    } else {
                        Text("No image selected").foregroundStyle(.secondary).font(.footnote)
                    }
                }
                .onChange(of: photoItem) { _, newItem in
                    Task {
                        if let newItem, let raw = try? await newItem.loadTransferable(type: Data.self) {
                            // 🔽 Optimize before storing
                            if let slim = downscaleImageData(
                                raw,
                                maxDimension: 1800,      // try 1600–2200 depending on sharpness you want
                                maxFileBytes: 700_000,   // ~0.7 MB; adjust for quality vs size
                                opaque: true
                            ) {
                                imageData = slim
                            } else {
                                // Fallback to original if downscale fails
                                imageData = raw
                            }
                        }
                    }
                }
            }
        }
    }
}
