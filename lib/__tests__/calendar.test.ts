import { addMonths, dayKey, monthMatrix, streakLength } from "../calendar";

describe("dayKey", () => {
  it("formats local dates with zero padding", () => {
    expect(dayKey(new Date(2026, 5, 12))).toBe("2026-06-12");
    expect(dayKey(new Date(2026, 0, 3))).toBe("2026-01-03");
  });

  it("accepts ISO strings and uses the local day", () => {
    const iso = new Date(2026, 5, 12, 23, 30).toISOString();
    expect(dayKey(iso)).toBe("2026-06-12");
  });
});

describe("monthMatrix", () => {
  it("returns Sunday-first rows of 7", () => {
    for (const week of monthMatrix(2026, 5)) {
      expect(week).toHaveLength(7);
    }
  });

  it("starts February 2026 on a Sunday with no leading pad", () => {
    const weeks = monthMatrix(2026, 1); // Feb 1 2026 is a Sunday
    expect(weeks[0][0]?.getDate()).toBe(1);
    expect(weeks.flat().filter(Boolean)).toHaveLength(28);
  });

  it("pads months that start mid-week", () => {
    const weeks = monthMatrix(2026, 5); // Jun 1 2026 is a Monday
    expect(weeks[0][0]).toBeNull();
    expect(weeks[0][1]?.getDate()).toBe(1);
    expect(weeks.flat().filter(Boolean)).toHaveLength(30);
  });

  it("handles leap years", () => {
    expect(monthMatrix(2024, 1).flat().filter(Boolean)).toHaveLength(29);
  });
});

describe("streakLength", () => {
  const today = new Date(2026, 5, 12);

  it("counts consecutive days ending today", () => {
    const days = new Set(["2026-06-10", "2026-06-11", "2026-06-12"]);
    expect(streakLength(days, today)).toBe(3);
  });

  it("keeps yesterday's streak alive before today's session", () => {
    const days = new Set(["2026-06-10", "2026-06-11"]);
    expect(streakLength(days, today)).toBe(2);
  });

  it("breaks on a gap", () => {
    const days = new Set(["2026-06-08", "2026-06-09", "2026-06-11", "2026-06-12"]);
    expect(streakLength(days, today)).toBe(2);
  });

  it("is 0 with no recent sessions", () => {
    expect(streakLength(new Set(), today)).toBe(0);
    expect(streakLength(new Set(["2026-06-01"]), today)).toBe(0);
  });

  it("crosses month boundaries", () => {
    const days = new Set(["2026-05-30", "2026-05-31", "2026-06-01"]);
    expect(streakLength(days, new Date(2026, 5, 1))).toBe(3);
  });
});

describe("addMonths", () => {
  it("wraps across year boundaries both ways", () => {
    expect(addMonths(2026, 11, 1)).toEqual({ year: 2027, month: 0 });
    expect(addMonths(2026, 0, -1)).toEqual({ year: 2025, month: 11 });
    expect(addMonths(2026, 5, -7)).toEqual({ year: 2025, month: 10 });
  });
});
