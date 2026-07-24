import XCTest
import SwiftUI
@testable import IntervalTimer

/// The running pill must *fill* from its leading edge: the lit part gets a flat
/// trailing edge. Drawing it as its own capsule instead rounds that edge, which
/// reads as a small vertical bar sliding right rather than a pill filling up.
final class SegmentBarTests: XCTestCase {

    @MainActor
    func testRunningSliceFillsWithAFlatTrailingEdge() throws {
        // 4 equal segments across 800pt, 1pt seams → slices 199.25 wide.
        // Slice 1 spans x 200.25…399.5; half elapsed → lit through x ≈ 299.9.
        let cg = try render(segments: segments(4), index: 1, elapsedFraction: 0.5,
                            width: 800, height: 40)

        XCTAssertTrue(try isLit(cg, x: 210, y: 20), "running slice should be lit at its leading edge")
        XCTAssertTrue(try isLit(cg, x: 296, y: 4),
                      "lit part must reach the top row just inside the trailing edge")
        XCTAssertTrue(try isLit(cg, x: 296, y: 36),
                      "lit part must reach the bottom row just inside the trailing edge")
        XCTAssertFalse(try isLit(cg, x: 340, y: 20), "the rest of the running slice stays washed out")
        XCTAssertTrue(try isLit(cg, x: 100, y: 20), "finished slices read full")
        XCTAssertFalse(try isLit(cg, x: 500, y: 20), "future slices read washed out")
    }

    /// The slices are square and abut; only the bar's outer ends are rounded, so
    /// the whole thing reads as a single pill.
    @MainActor
    func testBarIsOnePillWithSquareSlices() throws {
        let cg = try render(segments: segments(4), index: 1, elapsedFraction: 0.5,
                            width: 800, height: 40)

        XCTAssertFalse(try isPainted(cg, x: 1, y: 1), "the bar's leading corner is clipped away")
        XCTAssertTrue(try isPainted(cg, x: 1, y: 20), "the leading cap is painted at mid-height")
        // Either side of the seam between slice 1 and slice 2, at the top row: square
        // slices paint right up to the seam, capsule-shaped ones would not.
        XCTAssertTrue(try isPainted(cg, x: 398, y: 1), "slice 1 is square at its trailing end")
        XCTAssertTrue(try isPainted(cg, x: 402, y: 1), "slice 2 is square at its leading end")
    }

    /// Too many segments for hairline seams: they're dropped rather than eating
    /// the slices, and the bar still fills.
    @MainActor
    func testDenseWorkoutDropsTheSeams() throws {
        // 200 segments across 300pt — 1pt seams would leave slices half a point wide.
        let cg = try render(segments: segments(200), index: 100, elapsedFraction: 0.5,
                            width: 300, height: 10)

        XCTAssertTrue(try isLit(cg, x: 100, y: 5), "elapsed part is lit")
        XCTAssertTrue(try isLit(cg, x: 140, y: 5), "lit through ~50% of the run")
        XCTAssertFalse(try isLit(cg, x: 250, y: 5), "remaining part stays washed out")
    }

    // MARK: helpers

    private func segments(_ count: Int, seconds: Int = 10) -> [Segment] {
        (0..<count).map { i in
            Segment(label: "S\(i)", seconds: seconds, color: "#FF0000",
                    round: 1, rounds: 1, intervalIndex: i, startsAt: i * seconds)
        }
    }

    @MainActor
    private func render(segments: [Segment], index: Int, elapsedFraction: Double,
                        width: CGFloat, height: CGFloat) throws -> CGImage {
        let bar = SegmentBar(segments: segments, index: index,
                             elapsedFraction: elapsedFraction, flood: false, height: height)
            .frame(width: width, height: height)
            .background(Color.black)
        let renderer = ImageRenderer(content: bar)
        renderer.scale = 1
        let image = try XCTUnwrap(renderer.uiImage)
        return try XCTUnwrap(image.cgImage)
    }

    /// Lit = the segment color at full strength; washed-out draws it at 0.3 over black.
    private func isLit(_ image: CGImage, x: Int, y: Int) throws -> Bool {
        let pixel = try XCTUnwrap(pixelRGBA(image, x: x, y: y))
        return pixel.r > 0.7 && pixel.g < 0.3 && pixel.b < 0.3
    }

    /// Any bar pixel, lit or washed out — the black backdrop shows through elsewhere.
    private func isPainted(_ image: CGImage, x: Int, y: Int) throws -> Bool {
        try XCTUnwrap(pixelRGBA(image, x: x, y: y)).r > 0.1
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
