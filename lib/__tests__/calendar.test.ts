import { addMonths, dayKey, monthMatrix } from "../calendar";

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

describe("addMonths", () => {
  it("wraps across year boundaries both ways", () => {
    expect(addMonths(2026, 11, 1)).toEqual({ year: 2027, month: 0 });
    expect(addMonths(2026, 0, -1)).toEqual({ year: 2025, month: 11 });
    expect(addMonths(2026, 5, -7)).toEqual({ year: 2025, month: 10 });
  });
});
