import { useCallback, useEffect, useRef, useState } from "react";
import { Segment, segmentAt, totalOfSegments } from "./timer";

export type TimerPhase = "running" | "paused" | "done";

export interface TimerCallbacks {
  onSegmentChange?: (index: number, segment: Segment) => void;
  /** Fires once per whole second for the last 3 seconds of every segment. */
  onCountdownTick?: (secondsLeft: number) => void;
  onFinish?: () => void;
}

/**
 * Timestamp-based engine: elapsed is always recomputed from Date.now(),
 * so pauses and JS stalls never accumulate drift.
 */
export function useIntervalTimer(segments: Segment[], callbacks: TimerCallbacks = {}) {
  const total = totalOfSegments(segments);

  const [phase, setPhase] = useState<TimerPhase>("running");
  const [index, setIndex] = useState(0);
  const [remaining, setRemaining] = useState(segments[0]?.seconds ?? 0);
  const [fraction, setFraction] = useState(1);
  const [totalRemaining, setTotalRemaining] = useState(total);

  const startedAtRef = useRef(Date.now());
  const pausedAccumMsRef = useRef(0);
  const pausedAtRef = useRef<number | null>(null);
  const lastIndexRef = useRef(0);
  const lastWholeRef = useRef(segments[0]?.seconds ?? 0);
  const finishedRef = useRef(false);
  const callbacksRef = useRef(callbacks);
  callbacksRef.current = callbacks;

  const elapsedNow = useCallback(() => {
    const pausedMs =
      pausedAccumMsRef.current + (pausedAtRef.current ? Date.now() - pausedAtRef.current : 0);
    return (Date.now() - startedAtRef.current - pausedMs) / 1000;
  }, []);

  const sync = useCallback(() => {
    const elapsed = elapsedNow();
    const pos = segmentAt(segments, elapsed);
    if (pos.done) {
      setIndex(pos.index);
      setRemaining(0);
      setFraction(0);
      setTotalRemaining(0);
      setPhase("done");
      if (!finishedRef.current) {
        finishedRef.current = true;
        callbacksRef.current.onFinish?.();
      }
      return;
    }
    const segment = segments[pos.index];
    const whole = Math.ceil(pos.remaining);
    if (pos.index !== lastIndexRef.current) {
      lastIndexRef.current = pos.index;
      lastWholeRef.current = whole;
      callbacksRef.current.onSegmentChange?.(pos.index, segment);
    } else if (whole !== lastWholeRef.current) {
      lastWholeRef.current = whole;
      if (whole >= 1 && whole <= 3) callbacksRef.current.onCountdownTick?.(whole);
    }
    setIndex(pos.index);
    setRemaining(whole);
    setFraction(pos.remaining / segment.seconds);
    setTotalRemaining(Math.max(0, total - elapsed));
  }, [segments, total, elapsedNow]);

  useEffect(() => {
    if (phase !== "running") return;
    const handle = setInterval(sync, 100);
    return () => clearInterval(handle);
  }, [phase, sync]);

  const setElapsed = useCallback(
    (seconds: number) => {
      const pausedMs =
        pausedAccumMsRef.current + (pausedAtRef.current ? Date.now() - pausedAtRef.current : 0);
      startedAtRef.current = Date.now() - pausedMs - seconds * 1000;
      sync();
    },
    [sync],
  );

  const pause = useCallback(() => {
    setPhase((p) => {
      if (p !== "running") return p;
      pausedAtRef.current = Date.now();
      return "paused";
    });
  }, []);

  const resume = useCallback(() => {
    setPhase((p) => {
      if (p !== "paused") return p;
      if (pausedAtRef.current) {
        pausedAccumMsRef.current += Date.now() - pausedAtRef.current;
        pausedAtRef.current = null;
      }
      return "running";
    });
  }, []);

  const skipNext = useCallback(() => {
    if (finishedRef.current) return;
    const next = segments[lastIndexRef.current + 1];
    setElapsed(next ? next.startsAt : total);
  }, [segments, total, setElapsed]);

  const skipPrev = useCallback(() => {
    if (finishedRef.current) return;
    const current = segments[lastIndexRef.current];
    if (!current) return;
    const intoCurrent = elapsedNow() - current.startsAt;
    if (intoCurrent > 1.5 || lastIndexRef.current === 0) {
      setElapsed(current.startsAt);
    } else {
      setElapsed(segments[lastIndexRef.current - 1].startsAt);
    }
  }, [segments, elapsedNow, setElapsed]);

  return {
    phase,
    index,
    segment: segments[index] as Segment | undefined,
    /** Whole seconds left in the current segment. */
    remaining,
    /** Fraction (0–1) of the current segment remaining — drives the ring. */
    fraction,
    totalRemaining,
    pause,
    resume,
    skipNext,
    skipPrev,
  };
}
