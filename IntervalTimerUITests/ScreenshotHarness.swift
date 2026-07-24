import XCTest

/// Temporary harness for the 1.7 redesign: drives the app to each screen and
/// attaches a full-screen PNG, so the shots can be diffed against the design
/// mocks. Delete this target once the redesign lands.
final class ScreenshotHarness: XCTestCase {

    override func setUp() { continueAfterFailure = false }

    // MARK: launch

    /// UserDefaults keys are settable from the command line (argument domain),
    /// so each shot picks its own theme / run style without touching app code.
    @discardableResult
    private func launch(theme: String = "dark", runStyle: String = "flood") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-hiit.theme", theme, "-hiit.runStyle", runStyle]
        app.launch()
        return app
    }

    /// Sheets and pushes animate — settle before capturing or the shot catches
    /// the presentation mid-flight.
    private func snap(_ app: XCUIApplication, _ name: String) {
        Thread.sleep(forTimeInterval: 1.5)
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }

    /// SwiftUI buttons frequently report isHittable == false — tap the center.
    private func tapCenter(_ element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    // MARK: screens

    func testWorkoutsDark() {
        let app = launch(theme: "dark")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        snap(app, "workouts-dark")
    }

    func testWorkoutsLight() {
        let app = launch(theme: "light")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        snap(app, "workouts-light")
    }

    func testHistoryDark() {
        let app = launch(theme: "dark")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons["History"].firstMatch)
        snap(app, "history-dark")
    }

    func testEditorDark() {
        let app = launch(theme: "dark")
        XCTAssertTrue(app.staticTexts["Tabata 20/10"].waitForExistence(timeout: 10))
        tapCenter(app.staticTexts["Tabata 20/10"])
        snap(app, "editor-dark")
    }

    func testRunFloodDark() {
        let app = launch(theme: "dark", runStyle: "flood")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "play").firstMatch)
        // Let the 3s "Get ready" pre-roll finish so the shot lands on a work interval.
        Thread.sleep(forTimeInterval: 4)
        snap(app, "run-flood-dark")
    }

    func testRunRingDark() {
        let app = launch(theme: "dark", runStyle: "ring")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "play").firstMatch)
        Thread.sleep(forTimeInterval: 4)
        snap(app, "run-ring-dark")
    }

    func testRunRingLight() {
        let app = launch(theme: "light", runStyle: "ring")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "play").firstMatch)
        Thread.sleep(forTimeInterval: 4)
        snap(app, "run-ring-light")
    }

    /// Start a run, then go home so the Dynamic Island shows the Live Activity.
    func testLiveActivityIsland() {
        let app = launch(theme: "dark", runStyle: "flood")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "play").firstMatch)
        Thread.sleep(forTimeInterval: 4)
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        snap(app, "live-activity-island")
        // Long-press the island to expand it.
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.028))
            .press(forDuration: 1.2)
        snap(app, "live-activity-expanded")
    }

    /// Skip through every interval to reach the finish screen.
    func testFinishDark() {
        let app = launch(theme: "dark", runStyle: "flood")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "play").firstMatch)
        let skip = app.buttons.matching(identifier: "skipNext").firstMatch
        XCTAssertTrue(skip.waitForExistence(timeout: 5))
        for _ in 0..<20 where skip.exists { tapCenter(skip) }
        snap(app, "finish-dark")
    }

    func testHistoryLight() {
        let app = launch(theme: "light")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons["History"].firstMatch)
        snap(app, "history-light")
    }

    func testEditorLight() {
        let app = launch(theme: "light")
        XCTAssertTrue(app.staticTexts["Tabata 20/10"].waitForExistence(timeout: 10))
        tapCenter(app.staticTexts["Tabata 20/10"])
        snap(app, "editor-light")
    }

    func testSettingsLight() {
        let app = launch(theme: "light")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "settings").firstMatch)
        snap(app, "settings-light")
    }

    func testSettingsDark() {
        let app = launch(theme: "dark")
        XCTAssertTrue(app.staticTexts["Workouts"].waitForExistence(timeout: 10))
        tapCenter(app.buttons.matching(identifier: "settings").firstMatch)
        snap(app, "settings-dark")
    }
}
