// Tiny in-memory login throttle (per process). Fine for a mini-project; use Redis in production.
const WINDOW_MS = 15 * 60 * 1000;
const MAX_FAILS = 5;
const fails = new Map<string, { count: number; first: number }>();

export function isLocked(key: string): boolean {
  const e = fails.get(key);
  if (!e) return false;
  if (Date.now() - e.first > WINDOW_MS) {
    fails.delete(key);
    return false;
  }
  return e.count >= MAX_FAILS;
}

export function recordFailure(key: string) {
  const e = fails.get(key);
  if (!e || Date.now() - e.first > WINDOW_MS) fails.set(key, { count: 1, first: Date.now() });
  else e.count += 1;
}

export function clearFailures(key: string) {
  fails.delete(key);
}
