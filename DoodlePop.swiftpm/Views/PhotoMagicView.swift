import SwiftUI
import PhotosUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Photo Magic — turn a photo into a black-and-white coloring page.
/// Flow: pick photo → preview converted line-art → "Color it!" → Canvas.
struct PhotoMagicView: View {
    let navigate: (AppRoute) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var sourceImage: UIImage?
    @State private var convertedImage: UIImage?
    @State private var isConverting = false
    @State private var pickedFromCamera = false

    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 24) {
                header

                ZStack {
                    SketchyCard(fill: .white, corner: 24) { EmptyView() }
                    Group {
                        if isConverting {
                            VStack(spacing: 10) {
                                ProgressView().tint(Theme.Palette.ink)
                                Text("Making your coloring page…")
                                    .font(Theme.Fonts.hand(18))
                            }
                        } else if let img = convertedImage {
                            Image(uiImage: img).resizable().scaledToFit().padding(24)
                        } else if let img = sourceImage {
                            Image(uiImage: img).resizable().scaledToFit().padding(24)
                                .overlay(
                                    Text("Tap Convert to magic ✨")
                                        .font(Theme.Fonts.hand(20))
                                        .padding(8)
                                        .background(Capsule().fill(.white))
                                        .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 2))
                                        .padding(20),
                                    alignment: .bottom
                                )
                        } else {
                            placeholder
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 480)
                .padding(.horizontal, 40)

                controls
            }
            .padding(.vertical, 28)
        }
        .onChange(of: pickerItem) { _, new in
            Task { await loadPicked(new) }
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Photo magic ✨").font(Theme.Fonts.caveat(40))
                Text("Turn a photo into a coloring page")
                    .font(Theme.Fonts.hand(18)).foregroundStyle(Theme.Palette.muted)
            }
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private var placeholder: some View {
        VStack(spacing: 14) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 64, weight: .bold))
                .foregroundStyle(Theme.Palette.muted)
            Text("Pick a photo to start")
                .font(Theme.Fonts.caveat(28))
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var controls: some View {
        HStack(spacing: 14) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Text("Pick photo")
                    .font(Theme.Fonts.hand(18))
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(Capsule().fill(Theme.Palette.accentYellow))
                    .overlay(Capsule().stroke(Theme.Palette.ink, lineWidth: 2))
                    .hardShadow()
            }
            if sourceImage != nil && convertedImage == nil && !isConverting {
                SketchyPill(label: "Convert ✨", fill: Theme.Palette.accentRed, foreground: .white) {
                    convert()
                }
            }
            if let converted = convertedImage {
                SketchyPill(label: "Color it! 🎨", fill: Theme.Palette.accentTeal) {
                    navigate(.canvas(templateID: nil, drawingID: nil,
                                     photoPNG: converted.pngData()))
                }
            }
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    @MainActor
    private func loadPicked(_ item: PhotosPickerItem?) async {
        convertedImage = nil
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let img = UIImage(data: data) else { return }
        sourceImage = img
    }

    private func convert() {
        guard let src = sourceImage else { return }
        isConverting = true
        Task.detached(priority: .userInitiated) {
            let out = ColoringPageMaker.convert(src)
            await MainActor.run {
                convertedImage = out
                isConverting = false
            }
        }
    }
}

/// Photo → coloring page pipeline (runs entirely on device):
/// 0) Vision person segmentation — if a person is found, the background is
///    whited out so the coloring page is just them, no clutter,
/// 1) downscale, 2) smoothing (CIMedian), 3) edges (CIEdges),
/// 4) invert + 5) threshold for clean black lines on white.
enum ColoringPageMaker {
    static func convert(_ image: UIImage) -> UIImage? {
        guard var ci = CIImage(image: image) else { return nil }

        // 0) Drop the background when there's clearly a person in the photo.
        if let masked = personMasked(ci) {
            ci = masked
        }

        // 1) Downscale to keep edges chunky and kid-friendly.
        let target: CGFloat = 1200
        let scale = min(1, target / max(ci.extent.width, ci.extent.height))
        let scaled = ci.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // 2) Smooth to drop fine noise.
        let smoothed = scaled
            .applyingFilter("CIMedianFilter")
            .applyingFilter("CINoiseReduction",
                            parameters: [kCIInputSharpnessKey: 0.0,
                                         "inputNoiseLevel": 0.04])

        // 3) Edges.
        let edges = smoothed.applyingFilter("CIEdges",
                                            parameters: [kCIInputIntensityKey: 8.0])

        // 4) Invert (edges are bright on dark → we want dark on light).
        let inverted = edges
            .applyingFilter("CIColorInvert")
            .applyingFilter("CIColorControls",
                            parameters: [kCIInputSaturationKey: 0.0,
                                         kCIInputContrastKey: 1.6,
                                         kCIInputBrightnessKey: 0.05])

        // 5) Hard threshold → pure black lines on pure white, so the canvas
        //    can blend the page with .multiply and flood fill sees clean walls.
        let thresholded = inverted.applyingFilter("CIColorThreshold",
                                                  parameters: ["inputThreshold": 0.6])

        let context = CIContext()
        guard let cg = context.createCGImage(thresholded, from: thresholded.extent) else { return nil }
        return UIImage(cgImage: cg)
    }

    /// Person on white background, or nil when no person is detected
    /// (pets, toys and landscapes keep the full frame).
    private static func personMasked(_ input: CIImage) -> CIImage? {
        let request = VNGeneratePersonSegmentationRequest()
        request.qualityLevel = .balanced
        request.outputPixelFormat = kCVPixelFormatType_OneComponent8

        let handler = VNImageRequestHandler(ciImage: input)
        guard (try? handler.perform([request])) != nil,
              let buffer = request.results?.first?.pixelBuffer else { return nil }

        var mask = CIImage(cvPixelBuffer: buffer)
        let sx = input.extent.width / mask.extent.width
        let sy = input.extent.height / mask.extent.height
        mask = mask.transformed(by: CGAffineTransform(scaleX: sx, y: sy))

        // Reject empty masks (no person) — average brightness ≈ person coverage.
        let avg = mask.applyingFilter("CIAreaAverage",
                                      parameters: [kCIInputExtentKey: CIVector(cgRect: mask.extent)])
        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(avg, toBitmap: &pixel, rowBytes: 4,
                           bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
                           format: .RGBA8, colorSpace: nil)
        guard pixel[0] > 8 else { return nil }   // < ~3% person pixels → skip

        let white = CIImage(color: .white).cropped(to: input.extent)
        return input.applyingFilter("CIBlendWithMask",
                                    parameters: [kCIInputBackgroundImageKey: white,
                                                 kCIInputMaskImageKey: mask])
    }
}
