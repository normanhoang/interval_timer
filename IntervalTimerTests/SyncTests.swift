import XCTest
@testable import IntervalTimer

final class SyncTests: XCTestCase {
    private func defaults() -> UserDefaults {
        let suite = "SyncTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testSessionDictionaryIsAValidPropertyListAndRoundTrips() throws {
        let dto = SessionDTO(
            uuid: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            workoutId: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            workoutName: "Intervals",
            totalSeconds: 90,
            completedAt: Date(timeIntervalSince1970: 100))

        let payload = dto.toDictionary()
        let decoded = try XCTUnwrap(SessionDTO(userInfo: payload))

        XCTAssertEqual(decoded.uuid, dto.uuid)
        XCTAssertEqual(decoded.workoutId, dto.workoutId)
        XCTAssertEqual(decoded.workoutName, "Intervals")
        XCTAssertEqual(decoded.totalSeconds, 90)
        XCTAssertEqual(decoded.completedAt, dto.completedAt)
        XCTAssertNil(decoded.completedIntervals)
        XCTAssertNil(decoded.totalIntervals)
        XCTAssertNil(decoded.pauseCount)
        XCTAssertTrue(PropertyListSerialization.propertyList(payload, isValidFor: .binary))
        XCTAssertNoThrow(try PropertyListSerialization.data(
            fromPropertyList: payload, format: .binary, options: 0))
    }

    func testSessionDictionaryRejectsAnUnrelatedPayload() {
        XCTAssertNil(SessionDTO(userInfo: [SyncKeys.cueKind: "tick"]))
    }

    /// A transfer queued by a pre-1.8 watch build can still land after the update.
    func testSessionDecodesThePre18FieldPerKeyPayload() throws {
        let intervals = [Interval(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
            label: "Sprint", seconds: 30, color: "#123456")]
        let legacy: [String: Any] = [
            SyncKeys.Legacy.sessionUUID: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA",
            SyncKeys.Legacy.sessionWorkoutId: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB",
            SyncKeys.Legacy.sessionWorkoutName: "Intervals",
            SyncKeys.Legacy.sessionTotalSeconds: 90,
            SyncKeys.Legacy.sessionCompletedAt: Date(timeIntervalSince1970: 100),
            SyncKeys.Legacy.sessionPauseCount: 2,
            SyncKeys.Legacy.sessionWorkoutIntervals: try JSONEncoder().encode(intervals),
            SyncKeys.Legacy.sessionWorkoutRepeats: 3,
        ]

        let decoded = try XCTUnwrap(SessionDTO(userInfo: legacy))

        XCTAssertEqual(decoded.uuid, UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA"))
        XCTAssertEqual(decoded.workoutName, "Intervals")
        XCTAssertEqual(decoded.totalSeconds, 90)
        XCTAssertEqual(decoded.completedAt, Date(timeIntervalSince1970: 100))
        XCTAssertEqual(decoded.pauseCount, 2)
        XCTAssertNil(decoded.completedIntervals)
        XCTAssertEqual(decoded.workoutIntervals, intervals)
        XCTAssertEqual(decoded.workoutRepeats, 3)
    }

    func testSessionDictionaryRoundTripsWorkoutSnapshot() throws {
        let intervals = [Interval(
            id: UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!,
            label: "Sprint", seconds: 30, color: "#123456")]
        let dto = SessionDTO(
            uuid: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            workoutId: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            workoutName: "Intervals", totalSeconds: 90,
            completedAt: Date(timeIntervalSince1970: 100),
            workoutIntervals: intervals, workoutRepeats: 3)

        let payload = dto.toDictionary()
        let decoded = try XCTUnwrap(SessionDTO(userInfo: payload))

        XCTAssertEqual(decoded.workoutIntervals, intervals)
        XCTAssertEqual(decoded.workoutRepeats, 3)
        XCTAssertTrue(PropertyListSerialization.propertyList(payload, isValidFor: .binary))
    }

    func testSessionOutboxPersistsUntilSpecificSessionIsRemoved() throws {
        let defaults = defaults()
        let first = SessionDTO(
            uuid: UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!,
            workoutId: UUID(), workoutName: "First", totalSeconds: 30)
        let second = SessionDTO(
            uuid: UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!,
            workoutId: UUID(), workoutName: "Second", totalSeconds: 60)

        SessionOutbox(defaults: defaults).enqueue(first)
        SessionOutbox(defaults: defaults).enqueue(second)
        let restored = SessionOutbox(defaults: defaults)
        XCTAssertEqual(restored.pending().map(\.uuid), [first.uuid, second.uuid])

        restored.remove(uuid: first.uuid)
        XCTAssertEqual(SessionOutbox(defaults: defaults).pending().map(\.uuid), [second.uuid])
    }

    func testSessionOutboxTreatsMalformedStorageAsEmpty() {
        let defaults = defaults()
        defaults.set(Data("not-json".utf8), forKey: SessionOutbox.storageKey)

        XCTAssertTrue(SessionOutbox(defaults: defaults).pending().isEmpty)
    }

    func testSessionOutboxConcurrentEnqueuesDoNotLoseSessions() {
        let outbox = SessionOutbox(defaults: defaults())
        let ids = (0..<40).map { _ in UUID() }

        DispatchQueue.concurrentPerform(iterations: ids.count) { index in
            outbox.enqueue(SessionDTO(
                uuid: ids[index], workoutId: UUID(), workoutName: "Concurrent",
                totalSeconds: index))
        }

        XCTAssertEqual(Set(outbox.pending().map(\.uuid)), Set(ids))
    }
}
