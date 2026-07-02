import XCTest
@testable import IntervalTimer

final class TimerTests: XCTestCase {
    let intervals = [
        Interval(label: "Work", seconds: 20, color: "#FED7AA"),
        Interval(label: "Rest", seconds: 10, color: "#BAE6FD"),
    ]
    let repeats = 2

    func flatten(_ preroll: Int = 0) -> [Segment] {
        TimerEngineMath.flattenWorkout(intervals: intervals, repeats: repeats, prerollSeconds: preroll)
    }

    // MARK: flattenWorkout

    func testExpandsRepeatsWithCumulativeOffsets() {
        let segments = flatten()
        XCTAssertEqual(segments.count, 4)
        XCTAssertEqual(segments.map(\.startsAt), [0, 20, 30, 50])
        XCTAssertEqual(segments.map(\.round), [1, 1, 2, 2])
        XCTAssertEqual(segments.map(\.label), ["Work", "Rest", "Work", "Rest"])
        XCTAssertEqual(segments.map(\.intervalIndex), [0, 1, 0, 1])
    }

    func testPrependsPreroll() {
        let segments = flatten(3)
        XCTAssertEqual(segments.count, 5)
        XCTAssertEqual(segments[0].label, "Get ready")
        XCTAssertEqual(segments[0].round, 0)
        XCTAssertEqual(segments[0].intervalIndex, -1)
        XCTAssertEqual(segments[0].startsAt, 0)
        XCTAssertEqual(segments[1].startsAt, 3)
        XCTAssertEqual(TimerEngineMath.totalOfSegments(segments), 63)
    }

    func testSkipsZeroSecondIntervals() {
        let segments = TimerEngineMath.flattenWorkout(
            intervals: [
                Interval(label: "Work", seconds: 30, color: "#fff"),
                Interval(label: "Nothing", seconds: 0, color: "#fff"),
            ],
            repeats: 2
        )
        XCTAssertEqual(segments.map(\.label), ["Work", "Work"])
        XCTAssertEqual(segments.map(\.startsAt), [0, 30])
    }

    // MARK: warm up / cool down

    func testWarmupAndCooldownAppearOnceRegardlessOfRepeats() {
        let segments = TimerEngineMath.flattenWorkout(
            intervals: intervals, repeats: 3, warmupSeconds: 60, cooldownSeconds: 30)
        XCTAssertEqual(segments.map(\.label),
                       ["Warm up", "Work", "Rest", "Work", "Rest", "Work", "Rest", "Cool down"])
        XCTAssertEqual(segments.first?.round, 0)
        XCTAssertEqual(segments.first?.intervalIndex, -1)
        XCTAssertEqual(segments.last?.round, 0)
        XCTAssertEqual(segments.last?.intervalIndex, -1)
    }

    func testWarmupCooldownOrderingAndOffsetsWithPreroll() {
        let segments = TimerEngineMath.flattenWorkout(
            intervals: intervals, repeats: 2, prerollSeconds: 3, warmupSeconds: 60, cooldownSeconds: 30)
        XCTAssertEqual(segments.map(\.label),
                       ["Get ready", "Warm up", "Work", "Rest", "Work", "Rest", "Cool down"])
        XCTAssertEqual(segments.map(\.startsAt), [0, 3, 63, 83, 93, 113, 123])
        XCTAssertEqual(TimerEngineMath.totalOfSegments(segments), 153)
    }

    func testZeroWarmupCooldownAddNoSegments() {
        let segments = TimerEngineMath.flattenWorkout(
            intervals: intervals, repeats: 2, warmupSeconds: 0, cooldownSeconds: 0)
        XCTAssertEqual(segments.count, 4)
        XCTAssertEqual(segments.map(\.label), ["Work", "Rest", "Work", "Rest"])
    }

    // MARK: totalDuration

    func testTotalDuration() {
        XCTAssertEqual(TimerEngineMath.totalDuration(intervals: intervals, repeats: repeats), 60)
    }

    func testTotalDurationIncludesWarmupCooldownOnce() {
        XCTAssertEqual(
            TimerEngineMath.totalDuration(
                intervals: intervals, repeats: 3, warmupSeconds: 60, cooldownSeconds: 30),
            180)
    }

    // MARK: segmentAt

    func testFindsSegmentAndRemaining() {
        let s = flatten()
        let a = TimerEngineMath.segmentAt(s, elapsed: 0)
        XCTAssertEqual(a.index, 0); XCTAssertEqual(a.remaining, 20); XCTAssertFalse(a.done)
        let b = TimerEngineMath.segmentAt(s, elapsed: 5.5)
        XCTAssertEqual(b.index, 0); XCTAssertEqual(b.remaining, 14.5, accuracy: 1e-9); XCTAssertFalse(b.done)
    }

    func testEdgeBelongsToNextSegment() {
        let s = flatten()
        let a = TimerEngineMath.segmentAt(s, elapsed: 20)
        XCTAssertEqual(a.index, 1); XCTAssertEqual(a.remaining, 10)
        let b = TimerEngineMath.segmentAt(s, elapsed: 30)
        XCTAssertEqual(b.index, 2); XCTAssertEqual(b.remaining, 20)
    }

    func testDoneAtAndPastTotal() {
        let s = flatten()
        let a = TimerEngineMath.segmentAt(s, elapsed: 60)
        XCTAssertEqual(a.index, 3); XCTAssertEqual(a.remaining, 0); XCTAssertTrue(a.done)
        XCTAssertTrue(TimerEngineMath.segmentAt(s, elapsed: 75).done)
    }

    func testTailOfLastSegment() {
        let pos = TimerEngineMath.segmentAt(flatten(), elapsed: 59.5)
        XCTAssertEqual(pos.index, 3)
        XCTAssertEqual(pos.remaining, 0.5, accuracy: 1e-9)
        XCTAssertFalse(pos.done)
    }

    func testEmptySegmentsAreDone() {
        let pos = TimerEngineMath.segmentAt([], elapsed: 0)
        XCTAssertEqual(pos.index, 0); XCTAssertEqual(pos.remaining, 0); XCTAssertTrue(pos.done)
    }

    // MARK: formatSeconds

    func testFormatSeconds() {
        XCTAssertEqual(TimerEngineMath.formatSeconds(0), "0:00")
        XCTAssertEqual(TimerEngineMath.formatSeconds(5), "0:05")
        XCTAssertEqual(TimerEngineMath.formatSeconds(65), "1:05")
        XCTAssertEqual(TimerEngineMath.formatSeconds(599), "9:59")
        XCTAssertEqual(TimerEngineMath.formatSeconds(3600), "1:00:00")
        XCTAssertEqual(TimerEngineMath.formatSeconds(3725), "1:02:05")
    }
}
