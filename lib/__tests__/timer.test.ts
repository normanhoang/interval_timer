import {
  flattenWorkout,
  formatSeconds,
  segmentAt,
  totalDuration,
  totalOfSegments,
} from "../timer";

const workout = {
  intervals: [
    { id: "a", label: "Work", seconds: 20, color: "#FED7AA" },
    { id: "b", label: "Rest", seconds: 10, color: "#BAE6FD" },
  ],
  repeats: 2,
};

describe("flattenWorkout", () => {
  it("expands repeats with cumulative offsets and round numbers", () => {
    const segments = flattenWorkout(workout);
    expect(segments).toHaveLength(4);
    expect(segments.map((s) => s.startsAt)).toEqual([0, 20, 30, 50]);
    expect(segments.map((s) => s.round)).toEqual([1, 1, 2, 2]);
    expect(segments.map((s) => s.label)).toEqual(["Work", "Rest", "Work", "Rest"]);
    expect(segments.map((s) => s.intervalIndex)).toEqual([0, 1, 0, 1]);
  });

  it("prepends a pre-roll segment and shifts offsets", () => {
    const segments = flattenWorkout(workout, 3);
    expect(segments).toHaveLength(5);
    expect(segments[0]).toMatchObject({ label: "Get ready", round: 0, intervalIndex: -1, startsAt: 0 });
    expect(segments[1].startsAt).toBe(3);
    expect(totalOfSegments(segments)).toBe(63);
  });

  it("skips zero-second intervals", () => {
    const segments = flattenWorkout({
      intervals: [
        { id: "a", label: "Work", seconds: 30, color: "#fff" },
        { id: "b", label: "Nothing", seconds: 0, color: "#fff" },
      ],
      repeats: 2,
    });
    expect(segments.map((s) => s.label)).toEqual(["Work", "Work"]);
    expect(segments.map((s) => s.startsAt)).toEqual([0, 30]);
  });
});

describe("totalDuration", () => {
  it("multiplies the interval sum by repeats", () => {
    expect(totalDuration(workout)).toBe(60);
  });
});

describe("segmentAt", () => {
  const segments = flattenWorkout(workout);

  it("finds the segment and fractional remaining", () => {
    expect(segmentAt(segments, 0)).toEqual({ index: 0, remaining: 20, done: false });
    expect(segmentAt(segments, 5.5)).toEqual({ index: 0, remaining: 14.5, done: false });
  });

  it("treats an exact segment edge as the next segment", () => {
    expect(segmentAt(segments, 20)).toEqual({ index: 1, remaining: 10, done: false });
    expect(segmentAt(segments, 30)).toEqual({ index: 2, remaining: 20, done: false });
  });

  it("reports done at and past the total duration", () => {
    expect(segmentAt(segments, 60)).toEqual({ index: 3, remaining: 0, done: true });
    expect(segmentAt(segments, 75).done).toBe(true);
  });

  it("handles the tail of the last segment", () => {
    const pos = segmentAt(segments, 59.5);
    expect(pos.index).toBe(3);
    expect(pos.remaining).toBeCloseTo(0.5);
    expect(pos.done).toBe(false);
  });

  it("is done for empty segment lists", () => {
    expect(segmentAt([], 0)).toEqual({ index: 0, remaining: 0, done: true });
  });
});

describe("formatSeconds", () => {
  it("formats m:ss and h:mm:ss", () => {
    expect(formatSeconds(0)).toBe("0:00");
    expect(formatSeconds(5)).toBe("0:05");
    expect(formatSeconds(65)).toBe("1:05");
    expect(formatSeconds(599)).toBe("9:59");
    expect(formatSeconds(3600)).toBe("1:00:00");
    expect(formatSeconds(3725)).toBe("1:02:05");
  });
});
