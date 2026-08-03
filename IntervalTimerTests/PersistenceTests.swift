import SwiftData
import XCTest
@testable import IntervalTimer

final class PersistenceTests: XCTestCase {
    @MainActor
    func testSessionWorkoutSnapshotPersists() throws {
        let schema = Schema([Workout.self, Session.self])
        let container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)])
        let intervals = [Interval(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
            label: "Original", seconds: 45, color: "#123456")]
        container.mainContext.insert(Session(
            workoutId: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            workoutName: "Snapshot", totalSeconds: 135,
            workoutIntervals: intervals, workoutRepeats: 3))
        try container.mainContext.save()

        let context = ModelContext(container)
        let session = try XCTUnwrap(context.fetch(FetchDescriptor<Session>()).first)

        XCTAssertEqual(session.workoutIntervals, intervals)
        XCTAssertEqual(session.workoutRepeats, 3)
    }

    /// An unopenable store must degrade to the recovery screen, and resetting
    /// must actually clear the blockage rather than leaving the app stuck there.
    @MainActor
    func testBootstrapFallsBackAndResetRecovers() throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let storeURL = dir.appendingPathComponent("default.store")
        // A directory where the store file belongs: SwiftData can't open it.
        try FileManager.default.createDirectory(at: storeURL, withIntermediateDirectories: true)

        XCTAssertTrue(PersistenceBootstrap.load(storeURL: storeURL).failed)
        XCTAssertFalse(PersistenceBootstrap.reset(storeURL: storeURL).failed)
    }
}
