import XCTest
@testable import IntervalTimer

final class PaletteTests: XCTestCase {

    // MARK: flood grounds

    func testWorkAndRestUseTheDesignedStops() {
        XCTAssertEqual(Palette.floodHexes(Palette.work), ["#DE7272", "#B14F57", "#8E3F4B"])
        XCTAssertEqual(Palette.floodHexes(Palette.rest), ["#57B57F", "#3E8F66", "#2F7355"])
    }

    func testDerivedStopsGetProgressivelyDarker() {
        for hex in Palette.intervalColors {
            let stops = Palette.floodHexes(hex)
            XCTAssertEqual(stops.count, 3, hex)
            let luma = stops.map { s -> Double in
                let (r, g, b) = Palette.rgb(s)
                return 0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)
            }
            XCTAssertGreaterThan(luma[0], luma[1], "\(hex) stop 0 → 1")
            XCTAssertGreaterThan(luma[1], luma[2], "\(hex) stop 1 → 2")
        }
    }

    func testDerivedStopsKeepTheirHue() {
        // Sky #5FB8E0 (cool down) must stay blue, not drift toward grey/green.
        let stops = Palette.floodHexes("#5FB8E0")
        for stop in stops {
            let (r, g, b) = Palette.rgb(stop)
            XCTAssertGreaterThan(b, g, stop)
            XCTAssertGreaterThan(g, r, stop)
        }
    }

    func testShadeIsIdentityAtUnitScale() {
        XCTAssertEqual(Palette.shade("#5FB8E0", brightness: 1, saturation: 1), "#5FB8E0")
    }
}
