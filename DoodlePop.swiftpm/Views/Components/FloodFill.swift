import UIKit

/// Scanline-style raster flood fill for the paint-bucket tool.
///
/// The fill happens on a separate raster layer that sits *below* the PencilKit
/// strokes and the template line art. Boundaries are taken from a composite
/// "walls" image (template lines + kid's strokes): any opaque, non-near-white
/// pixel is a wall. Existing fills are NOT walls, so a region can be re-filled
/// with a new color by tapping again.
enum FloodFill {

    /// Returns a new fill-layer image of `size` where the region around `seed`
    /// is painted with `color`. Returns the unchanged layer when the seed lands
    /// on a wall pixel or out of bounds.
    static func fill(layer existing: UIImage?,
                     walls: UIImage,
                     size: CGSize,
                     seed: CGPoint,
                     color: UIColor) -> UIImage? {
        let w = Int(size.width.rounded()), h = Int(size.height.rounded())
        guard w > 1, h > 1,
              seed.x >= 0, seed.y >= 0,
              Int(seed.x) < w, Int(seed.y) < h else { return existing }

        let cs = CGColorSpaceCreateDeviceRGB()
        let info = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let wallCtx = CGContext(data: nil, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: cs, bitmapInfo: info),
              let fillCtx = CGContext(data: nil, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: cs, bitmapInfo: info)
        else { return existing }

        if let cg = walls.cgImage {
            wallCtx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        if let cg = existing?.cgImage {
            fillCtx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
        guard let wallData = wallCtx.data, let fillData = fillCtx.data else { return existing }
        let wp = wallData.bindMemory(to: UInt8.self, capacity: w * h * 4)
        let fp = fillData.bindMemory(to: UInt8.self, capacity: w * h * 4)

        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 1
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let nr = UInt8(max(0, min(255, r * 255)))
        let ng = UInt8(max(0, min(255, g * 255)))
        let nb = UInt8(max(0, min(255, b * 255)))

        // CGContext buffers are bottom-up; SwiftUI tap points are top-down.
        let sx = Int(seed.x), sy = h - 1 - Int(seed.y)

        // Wall = opaque-ish pixel that is not (near-)white. Anti-aliased line
        // edges count as walls too, which keeps fills from leaking through.
        @inline(__always) func isWall(_ i: Int) -> Bool {
            let o = i * 4
            let alpha = wp[o + 3]
            if alpha < 60 { return false }
            return !(wp[o] > 235 && wp[o + 1] > 235 && wp[o + 2] > 235)
        }

        let seedIdx = sy * w + sx
        guard !isWall(seedIdx) else { return existing }

        var visited = [Bool](repeating: false, count: w * h)
        var stack: [Int] = [seedIdx]
        stack.reserveCapacity(w * h / 8)
        visited[seedIdx] = true

        while let idx = stack.popLast() {
            let o = idx * 4
            fp[o] = nr; fp[o + 1] = ng; fp[o + 2] = nb; fp[o + 3] = 255

            let x = idx % w
            if x > 0 {
                let n = idx - 1
                if !visited[n] { visited[n] = true; if !isWall(n) { stack.append(n) } }
            }
            if x < w - 1 {
                let n = idx + 1
                if !visited[n] { visited[n] = true; if !isWall(n) { stack.append(n) } }
            }
            if idx >= w {
                let n = idx - w
                if !visited[n] { visited[n] = true; if !isWall(n) { stack.append(n) } }
            }
            if idx < w * (h - 1) {
                let n = idx + w
                if !visited[n] { visited[n] = true; if !isWall(n) { stack.append(n) } }
            }
        }

        guard let out = fillCtx.makeImage() else { return existing }
        return UIImage(cgImage: out)
    }
}

extension CGRect {
    /// Rect that aspect-fits `content` inside `self` (like .scaledToFit).
    func aspectFit(_ content: CGSize) -> CGRect {
        guard content.width > 0, content.height > 0 else { return self }
        let scale = min(width / content.width, height / content.height)
        let size = CGSize(width: content.width * scale, height: content.height * scale)
        return CGRect(x: midX - size.width / 2,
                      y: midY - size.height / 2,
                      width: size.width, height: size.height)
    }
}
