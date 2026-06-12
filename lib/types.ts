export interface Interval {
  id: string;
  label: string;
  seconds: number;
  /** Pastel hex from lib/colors.ts INTERVAL_COLORS. */
  color: string;
}

export interface Workout {
  id: string;
  name: string;
  intervals: Interval[];
  /** How many times the interval sequence repeats (rounds). */
  repeats: number;
  createdAt: string;
}

export interface Session {
  id: string;
  workoutId: string;
  workoutName: string;
  totalSeconds: number;
  completedAt: string;
}
