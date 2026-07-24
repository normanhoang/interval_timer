import XCTest

/// Temporary harness (1.7 redesign): drives the watch app to its run screen and
/// attaches a screenshot for diffing against the mocks. Delete with the phone
/// harness once the redesign lands.
final class WatchScreenshotHarness: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    private func snap(_ name: String) {
        Thread.sleep(forTimeInterval: 1.5)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    private func tapCenter(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func testList() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Tabata 20/10"].waitForExistence(timeout: 15))
        snap("watch-list")
    }

    func testRunFlood() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Tabata 20/10"].waitForExistence(timeout: 15))
        tapCenter(app.staticTexts["Tabata 20/10"])
        // Past the 3s "Get ready" pre-roll, into the first work interval.
        Thread.sleep(forTimeInterval: 5)
        snap("watch-run-flood")
    }
}
