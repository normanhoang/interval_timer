import { PREROLL_COLOR } from "./colors";
import { Workout } from "./types";

/** One concrete stretch of the timeline (repeats expanded, pre-roll prepended). */
export interface Segment {
  label: string;
  seconds: number;
  color: string;
  /** 1-based round number; 0 for the pre-roll. */
  round: number;
  rounds: number;
  /** Index into the workout's interval list; -1 for the pre-roll. */
  intervalIndex: number;
  /** Cumulative seconds from timer start. */
  startsAt: number;
}

type WorkoutShape = Pick<Workout, "intervals" | "repeats">;

export function flattenWorkout(workout: WorkoutShape, prerollSeconds = 0): Segment[] {
  const segments: Segment[] = [];
  let t = 0;
  if (prerollSeconds > 0) {
    segments.push({
      label: "Get ready",
      seconds: prerollSeconds,
      color: PREROLL_COLOR,
      round: 0,
      rounds: workout.repeats,
      intervalIndex: -1,
      startsAt: 0,
    });
    t = prerollSeconds;
  }
  for (let round = 1; round <= workout.repeats; round++) {
    workout.intervals.forEach((interval, intervalIndex) => {
      if (interval.seconds <= 0) return;
      segments.push({
        label: interval.label,
        seconds: interval.seconds,
        color: interval.color,
        round,
        rounds: workout.repeats,
        intervalIndex,
        startsAt: t,
      });
      t += interval.seconds;
    });
  }
  return segments;
}

export function totalDuration(workout: WorkoutShape): number {
  return workout.repeats * workout.intervals.reduce((sum, i) => sum + Math.max(0, i.seconds), 0);
}

export function totalOfSegments(segments: Segment[]): number {
  const last = segments[segments.length - 1];
  return last ? last.startsAt + last.seconds : 0;
}

export interface SegmentPosition {
  index: number;
  /** Seconds left in the current segment (fractional). */
  remaining: number;
  done: boolean;
}

/** Elapsed exactly on a segment edge belongs to the next segment. */
export function segmentAt(segments: Segment[], elapsed: number): SegmentPosition {
  const total = totalOfSegments(segments);
  if (segments.length === 0 || elapsed >= total) {
    return { index: Math.max(0, segments.length - 1), remaining: 0, done: true };
  }
  let index = 0;
  for (let i = 0; i < segments.length; i++) {
    if (elapsed >= segments[i].startsAt) index = i;
    else break;
  }
  const segment = segments[index];
  return { index, remaining: segment.startsAt + segment.seconds - elapsed, done: false };
}

export function formatSeconds(total: number): string {
  const t = Math.max(0, Math.round(total));
  const h = Math.floor(t / 3600);
  const m = Math.floor((t % 3600) / 60);
  const s = t % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${m}:${String(s).padStart(2, "0")}`;
}
