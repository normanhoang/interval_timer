import AsyncStorage from "@react-native-async-storage/async-storage";
import {
  ReactNode,
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { dayKey } from "./calendar";
import { REST_COLOR, WORK_COLOR } from "./colors";
import { Session, Workout } from "./types";

const WORKOUTS_KEY = "@hiit/workouts";
const SESSIONS_KEY = "@hiit/sessions";

export function uid(): string {
  return Math.random().toString(36).slice(2, 10) + Date.now().toString(36);
}

function seedWorkouts(): Workout[] {
  const now = new Date().toISOString();
  return [
    {
      id: uid(),
      name: "Tabata 20/10",
      intervals: [
        { id: uid(), label: "Work", seconds: 20, color: WORK_COLOR },
        { id: uid(), label: "Rest", seconds: 10, color: REST_COLOR },
      ],
      repeats: 8,
      createdAt: now,
    },
    {
      id: uid(),
      name: "Classic HIIT 40/20",
      intervals: [
        { id: uid(), label: "Work", seconds: 40, color: WORK_COLOR },
        { id: uid(), label: "Rest", seconds: 20, color: REST_COLOR },
      ],
      repeats: 6,
      createdAt: now,
    },
  ];
}

interface WorkoutsValue {
  hydrated: boolean;
  workouts: Workout[];
  sessions: Session[];
  getWorkout: (id: string | undefined) => Workout | undefined;
  addWorkout: (workout: Omit<Workout, "id" | "createdAt">) => Workout;
  reorderWorkouts: (next: Workout[]) => void;
  updateWorkout: (id: string, patch: Partial<Omit<Workout, "id" | "createdAt">>) => void;
  deleteWorkout: (id: string) => void;
  addSession: (session: Omit<Session, "id" | "completedAt">) => void;
  deleteSession: (id: string) => void;
  clearSessionsForDay: (day: string) => void;
  clearSessions: () => void;
}

const WorkoutsContext = createContext<WorkoutsValue | null>(null);

export function WorkoutsProvider({ children }: { children: ReactNode }) {
  const [hydrated, setHydrated] = useState(false);
  const [workouts, setWorkouts] = useState<Workout[]>([]);
  const [sessions, setSessions] = useState<Session[]>([]);

  useEffect(() => {
    (async () => {
      try {
        const [rawWorkouts, rawSessions] = await Promise.all([
          AsyncStorage.getItem(WORKOUTS_KEY),
          AsyncStorage.getItem(SESSIONS_KEY),
        ]);
        if (rawWorkouts == null) {
          const seeds = seedWorkouts();
          setWorkouts(seeds);
          AsyncStorage.setItem(WORKOUTS_KEY, JSON.stringify(seeds)).catch(() => {});
        } else {
          setWorkouts(JSON.parse(rawWorkouts));
        }
        if (rawSessions != null) setSessions(JSON.parse(rawSessions));
      } catch {
        setWorkouts(seedWorkouts());
      } finally {
        setHydrated(true);
      }
    })();
  }, []);

  const hydratedRef = useRef(false);
  hydratedRef.current = hydrated;

  const persistWorkouts = useCallback((next: Workout[]) => {
    if (hydratedRef.current) {
      AsyncStorage.setItem(WORKOUTS_KEY, JSON.stringify(next)).catch(() => {});
    }
    return next;
  }, []);

  const persistSessions = useCallback((next: Session[]) => {
    if (hydratedRef.current) {
      AsyncStorage.setItem(SESSIONS_KEY, JSON.stringify(next)).catch(() => {});
    }
    return next;
  }, []);

  const getWorkout = useCallback(
    (id: string | undefined) => workouts.find((w) => w.id === id),
    [workouts],
  );

  const addWorkout = useCallback(
    (workout: Omit<Workout, "id" | "createdAt">) => {
      const full: Workout = { ...workout, id: uid(), createdAt: new Date().toISOString() };
      setWorkouts((prev) => persistWorkouts([...prev, full]));
      return full;
    },
    [persistWorkouts],
  );

  const updateWorkout = useCallback(
    (id: string, patch: Partial<Omit<Workout, "id" | "createdAt">>) => {
      setWorkouts((prev) =>
        persistWorkouts(prev.map((w) => (w.id === id ? { ...w, ...patch } : w))),
      );
    },
    [persistWorkouts],
  );

  const reorderWorkouts = useCallback(
    (next: Workout[]) => {
      setWorkouts(() => persistWorkouts(next));
    },
    [persistWorkouts],
  );

  const deleteWorkout = useCallback(
    (id: string) => {
      setWorkouts((prev) => persistWorkouts(prev.filter((w) => w.id !== id)));
    },
    [persistWorkouts],
  );

  const addSession = useCallback(
    (session: Omit<Session, "id" | "completedAt">) => {
      const full: Session = { ...session, id: uid(), completedAt: new Date().toISOString() };
      setSessions((prev) => persistSessions([...prev, full]));
    },
    [persistSessions],
  );

  const deleteSession = useCallback(
    (id: string) => {
      setSessions((prev) => persistSessions(prev.filter((s) => s.id !== id)));
    },
    [persistSessions],
  );

  const clearSessionsForDay = useCallback(
    (day: string) => {
      setSessions((prev) => persistSessions(prev.filter((s) => dayKey(s.completedAt) !== day)));
    },
    [persistSessions],
  );

  const clearSessions = useCallback(() => {
    setSessions(() => persistSessions([]));
  }, [persistSessions]);

  const value = useMemo<WorkoutsValue>(
    () => ({
      hydrated,
      workouts,
      sessions,
      getWorkout,
      addWorkout,
      reorderWorkouts,
      updateWorkout,
      deleteWorkout,
      addSession,
      deleteSession,
      clearSessionsForDay,
      clearSessions,
    }),
    [
      hydrated,
      workouts,
      sessions,
      getWorkout,
      addWorkout,
      reorderWorkouts,
      updateWorkout,
      deleteWorkout,
      addSession,
      deleteSession,
      clearSessionsForDay,
      clearSessions,
    ],
  );

  return <WorkoutsContext.Provider value={value}>{children}</WorkoutsContext.Provider>;
}

export function useWorkouts(): WorkoutsValue {
  const value = useContext(WorkoutsContext);
  if (!value) throw new Error("useWorkouts must be used inside WorkoutsProvider");
  return value;
}
