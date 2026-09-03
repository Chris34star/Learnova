import { Users, Dumbbell, ListChecks, Gauge, CheckCircle2, AlertTriangle } from 'lucide-react';
import { SectionHeader } from './ui/SectionHeader';
import { Reveal } from './ui/Reveal';

const stats = [
  { icon: Users, label: 'Active students', value: '1,240' },
  { icon: Dumbbell, label: 'Learning sessions', value: '3,860' },
  { icon: ListChecks, label: 'Questions attempted', value: '52,300' },
  { icon: Gauge, label: 'Average mastery', value: '74%' },
];

export function SchoolDashboardPreview() {
  return (
    <section id="for-schools" className="py-20 lg:py-28">
      <div className="container-page">
        <Reveal>
          <SectionHeader
            eyebrow="For Schools"
            title="Students learn. Schools understand."
            description="Teachers and administrators can identify learning patterns across classes without reading every individual student session."
          />
        </Reveal>

        <Reveal delay={100}>
          <div className="mt-14 surface overflow-hidden p-0 shadow-lift">
            {/* Dashboard header */}
            <div className="border-b border-ink-200 bg-ink-50 px-6 py-4">
              <div className="flex items-center justify-between">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-wide text-ink-500">
                    School Dashboard
                  </p>
                  <h3 className="font-display text-lg font-bold text-ink-900">
                    Greenfield Academy
                  </h3>
                </div>
                <span className="rounded-lg bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                  Term 2 · 2026
                </span>
              </div>
            </div>

            <div className="p-6">
              {/* Stat grid */}
              <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
                {stats.map((s) => (
                  <div key={s.label} className="rounded-xl border border-ink-200 p-4">
                    <div className="mb-2 flex items-center gap-2">
                      <s.icon className="h-4 w-4 text-brand-600" />
                      <span className="text-xs font-medium text-ink-500">{s.label}</span>
                    </div>
                    <p className="font-display text-2xl font-bold text-ink-900">{s.value}</p>
                  </div>
                ))}
              </div>

              {/* Class insight */}
              <div className="mt-5 grid gap-5 lg:grid-cols-2">
                <div className="rounded-xl border border-ink-200 p-5">
                  <div className="mb-4 flex items-center justify-between">
                    <h4 className="font-display text-sm font-bold text-ink-900">
                      Class Insight
                    </h4>
                    <span className="rounded-md bg-ink-100 px-2.5 py-1 text-xs font-semibold text-ink-600">
                      Grade 8 Mathematics
                    </span>
                  </div>

                  <div className="space-y-4">
                    <div>
                      <div className="mb-1.5 flex items-center gap-2">
                        <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                        <span className="text-sm font-semibold text-ink-800">Strong area</span>
                      </div>
                      <p className="text-sm text-ink-600">Basic Algebra</p>
                      <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-ink-200">
                        <div className="h-full rounded-full bg-emerald-500" style={{ width: '82%' }} />
                      </div>
                    </div>

                    <div>
                      <div className="mb-1.5 flex items-center gap-2">
                        <AlertTriangle className="h-4 w-4 text-orange-600" />
                        <span className="text-sm font-semibold text-ink-800">Needs attention</span>
                      </div>
                      <p className="text-sm text-ink-600">Algebraic Word Problems</p>
                      <div className="mt-2 h-2 w-full overflow-hidden rounded-full bg-ink-200">
                        <div className="h-full rounded-full bg-orange-500" style={{ width: '41%' }} />
                      </div>
                    </div>
                  </div>
                </div>

                {/* Mastery distribution chart */}
                <div className="rounded-xl border border-ink-200 p-5">
                  <h4 className="font-display text-sm font-bold text-ink-900">
                    Mastery Distribution
                  </h4>
                  <p className="mt-1 text-xs text-ink-500">Across all Grade 8 topics</p>

                  <div className="mt-5 flex items-end justify-between gap-2">
                    {[
                      { label: 'Arith', v: 85 },
                      { label: 'Geom', v: 70 },
                      { label: 'B.Alg', v: 82 },
                      { label: 'A.WP', v: 41 },
                      { label: 'Stats', v: 64 },
                      { label: 'Frac', v: 76 },
                    ].map((bar, i) => (
                      <div key={i} className="flex flex-1 flex-col items-center gap-2">
                        <div className="flex h-28 w-full items-end justify-center">
                          <div
                            className={`w-full max-w-[24px] rounded-t-md transition-all duration-700 ${
                              bar.v < 50
                                ? 'bg-gradient-to-t from-orange-400 to-orange-500'
                                : 'bg-gradient-to-t from-brand-400 to-brand-600'
                            }`}
                            style={{ height: `${bar.v}%` }}
                          />
                        </div>
                        <span className="text-[10px] font-medium text-ink-500">{bar.label}</span>
                      </div>
                    ))}
                  </div>
                  <div className="mt-3 flex items-center gap-4 text-xs text-ink-500">
                    <span className="flex items-center gap-1.5">
                      <span className="h-2.5 w-2.5 rounded bg-brand-500" /> On track
                    </span>
                    <span className="flex items-center gap-1.5">
                      <span className="h-2.5 w-2.5 rounded bg-orange-500" /> Needs attention
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </Reveal>

        <Reveal delay={200}>
          <p className="mx-auto mt-8 max-w-2xl text-center text-sm text-ink-500">
            Teachers and administrators can identify learning patterns without
            reading every individual student session — and intervene early where
            it matters.
          </p>
        </Reveal>
      </div>
    </section>
  );
}
