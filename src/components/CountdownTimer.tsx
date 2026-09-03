import { useEffect, useState } from 'react';

function getTarget(): number {
  const stored = localStorage.getItem('learnova_launch_target');
  if (stored) {
    const ts = parseInt(stored, 10);
    if (!Number.isNaN(ts) && ts > Date.now()) return ts;
  }
  const target = Date.now() + 5 * 24 * 60 * 60 * 1000;
  localStorage.setItem('learnova_launch_target', String(target));
  return target;
}

function calcRemaining(target: number) {
  const diff = Math.max(0, target - Date.now());
  const days = Math.floor(diff / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diff / (1000 * 60 * 60)) % 24);
  const minutes = Math.floor((diff / (1000 * 60)) % 60);
  const seconds = Math.floor((diff / 1000) % 60);
  return { days, hours, minutes, seconds, done: diff === 0 };
}

export function CountdownTimer() {
  const [target, setTarget] = useState<number | null>(null);
  const [remaining, setRemaining] = useState(() => ({
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0,
    done: false,
  }));

  useEffect(() => {
    setTarget(getTarget());
  }, []);

  useEffect(() => {
    if (target === null) return;
    setRemaining(calcRemaining(target));
    const id = setInterval(() => setRemaining(calcRemaining(target)), 1000);
    return () => clearInterval(id);
  }, [target]);

  const units = [
    { label: 'Days', value: remaining.days },
    { label: 'Hours', value: remaining.hours },
    { label: 'Minutes', value: remaining.minutes },
    { label: 'Seconds', value: remaining.seconds },
  ];

  return (
    <div className="grid grid-cols-4 gap-3 sm:gap-4">
      {units.map((u) => (
        <div
          key={u.label}
          className="surface flex flex-col items-center justify-center p-4 sm:p-6"
        >
          <span className="font-display text-3xl font-extrabold tabular-nums text-ink-900 sm:text-5xl">
            {String(u.value).padStart(2, '0')}
          </span>
          <span className="mt-1 text-xs font-semibold uppercase tracking-wider text-ink-500 sm:text-sm">
            {u.label}
          </span>
        </div>
      ))}
    </div>
  );
}
