import { BookOpen, Code2, Flame, Target, TrendingUp, Sparkles } from 'lucide-react';
import { ProgressBar } from './ui/ProgressBar';
import { Badge } from './ui/Badge';

function DayPill({ day, active }: { day: string; active: boolean }) {
  return (
    <div
      className={`h-8 w-8 rounded-lg text-xs font-bold flex items-center justify-center ${
        active
          ? 'bg-brand-600 text-white'
          : 'bg-ink-100 text-ink-400'
      }`}
    >
      {day}
    </div>
  );
}

export function ProductPreview() {
  return (
    <div className="surface relative w-full overflow-hidden p-0 shadow-lift">
      {/* Browser chrome */}
      <div className="flex items-center gap-2 border-b border-ink-200 bg-ink-50 px-4 py-3">
        <div className="flex gap-1.5">
          <div className="h-3 w-3 rounded-full bg-ink-300" />
          <div className="h-3 w-3 rounded-full bg-ink-300" />
          <div className="h-3 w-3 rounded-full bg-ink-300" />
        </div>
        <div className="mx-auto flex items-center gap-2 rounded-md bg-white px-3 py-1 text-xs text-ink-400 ring-1 ring-ink-200">
          <span className="h-2 w-2 rounded-full bg-brand-500" />
          learnova.app/dashboard
        </div>
      </div>

      {/* Dashboard body */}
      <div className="bg-white p-5 sm:p-6">
        {/* Greeting */}
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm text-ink-500">Good morning,</p>
            <h3 className="font-display text-xl font-bold text-ink-900">Amara 👋</h3>
          </div>
          <Badge variant="brand">
            <Flame className="h-3.5 w-3.5 text-accent-500" />
            12 day streak
          </Badge>
        </div>

        {/* Today's goal */}
        <div className="mt-4 flex items-center gap-3 rounded-xl border border-brand-200 bg-brand-50 p-4">
          <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-lg bg-brand-600 text-white">
            <Target className="h-5 w-5" />
          </div>
          <div className="flex-1">
            <p className="text-xs font-semibold uppercase tracking-wide text-brand-700">
              Today's Goal
            </p>
            <p className="text-sm font-medium text-ink-800">
              30 min of Algebra practice
            </p>
          </div>
          <span className="text-2xl font-bold text-brand-700">30<span className="text-sm font-medium text-brand-600">min</span></span>
        </div>

        {/* Progress cards */}
        <div className="mt-4 grid grid-cols-2 gap-3">
          <div className="rounded-xl border border-ink-200 p-4">
            <div className="mb-3 flex items-center gap-2">
              <BookOpen className="h-4 w-4 text-brand-600" />
              <span className="text-sm font-semibold text-ink-800">Mathematics</span>
            </div>
            <ProgressBar value={72} size="sm" />
            <p className="mt-2 text-xs text-ink-500">Algebra · Linear Equations</p>
          </div>
          <div className="rounded-xl border border-ink-200 p-4">
            <div className="mb-3 flex items-center gap-2">
              <Code2 className="h-4 w-4 text-accent-600" />
              <span className="text-sm font-semibold text-ink-800">Skills Lab</span>
            </div>
            <ProgressBar value={45} size="sm" />
            <p className="mt-2 text-xs text-ink-500">Web Creator · CSS next</p>
          </div>
        </div>

        {/* Weekly activity */}
        <div className="mt-4 rounded-xl border border-ink-200 p-4">
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-2">
              <TrendingUp className="h-4 w-4 text-brand-600" />
              <span className="text-sm font-semibold text-ink-800">This Week</span>
            </div>
            <span className="text-xs text-ink-500">4h 20m studied</span>
          </div>
          <div className="flex items-end justify-between gap-2">
            {[
              { day: 'M', h: 40 },
              { day: 'T', h: 65 },
              { day: 'W', h: 30 },
              { day: 'T', h: 80 },
              { day: 'F', h: 55 },
              { day: 'S', h: 90 },
              { day: 'S', h: 20 },
            ].map((d, i) => (
              <div key={i} className="flex flex-1 flex-col items-center gap-1.5">
                <div className="flex h-20 w-full items-end justify-center">
                  <div
                    className="w-full max-w-[18px] rounded-t-md bg-gradient-to-t from-brand-400 to-brand-600 transition-all duration-700"
                    style={{ height: `${d.h}%` }}
                  />
                </div>
                <DayPill day={d.day} active={i === 5} />
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Floating Nuru indicator */}
      <div className="absolute bottom-4 right-4 flex items-center gap-2 rounded-full bg-white py-1.5 pl-1.5 pr-3 shadow-lift ring-1 ring-ink-200 animate-breathe">
        <span className="flex h-7 w-7 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-brand-700 text-white">
          <Sparkles className="h-3.5 w-3.5" />
        </span>
        <span className="text-xs font-semibold text-ink-700">Need help?</span>
      </div>
    </div>
  );
}
