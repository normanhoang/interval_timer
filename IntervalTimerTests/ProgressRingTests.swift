import XCTest
import SwiftUI
@testable import IntervalTimer

/// The depletion gap must open exactly at 12 o'clock. The round line cap paints
/// strokeWidth/2 beyond the trim start point, so without compensation the arc's
/// visible edge sits left of top center.
final class ProgressRingTests: XCTestCase {

    @MainActor
    func testArcPaintEdgeIsAtTopCenter() throws {
        let size: CGFloat = 200
        let strokeWidth: CGFloat = 20
        // Circle().stroke centers the stroke on the path, radius = size/2;
        // sample inside the stroke band, clear of both edges.
        // Cap protrusion = 10pt arc ≈ 5.7°; sample at ±3° from top.
        let radius = size / 2 - strokeWidth / 4

        let ring = ProgressRing(size: size, strokeWidth: strokeWidth,
                                progress: 0.5, color: .red) { EmptyView() }
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: ring)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.uiImage)
        let cg = try XCTUnwrap(image.cgImage)

        func isRed(atDegreesFromTop deg: Double) throws -> Bool {
            let rad = deg * .pi / 180
            let x = Int((size / 2 + radius * sin(rad)).rounded())
            let y = Int((size / 2 - radius * cos(rad)).rounded())
            let pixel = try XCTUnwrap(pixelRGBA(cg, x: x, y: y))
            return pixel.r > 0.7 && pixel.g < 0.3 && pixel.b < 0.3
        }

        // Just right of top: inside the arc, must be painted.
        XCTAssertTrue(try isRed(atDegreesFromTop: 3),
                      "arc should be painted just right of top center")
        // Just left of top: must be the gap, not cap overhang.
        XCTAssertFalse(try isRed(atDegreesFromTop: -3),
                       "arc paint must not extend left of top center")
    }

    private func pixelRGBA(_ image: CGImage, x: Int, y: Int) -> (r: Double, g: Double, b: Double, a: Double)? {
        guard x >= 0, y >= 0, x < image.width, y < image.height else { return nil }
        var data = [UInt8](repeating: 0, count: 4)
        guard let ctx = CGContext(data: &data, width: 1, height: 1,
                                  bitsPerComponent: 8, bytesPerRow: 4,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        ctx.draw(image, in: CGRect(x: -x, y: y - image.height + 1,
                                   width: image.width, height: image.height))
        return (Double(data[0]) / 255, Double(data[1]) / 255,
                Double(data[2]) / 255, Double(data[3]) / 255)
    }
}
