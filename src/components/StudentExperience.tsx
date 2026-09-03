import { Target, BookOpen, Code2, FileText, Flame, Clock, ArrowRight } from 'lucide-react';
import { SectionHeader } from './ui/SectionHeader';
import { ProgressBar } from './ui/ProgressBar';
import { Badge } from './ui/Badge';
import { Reveal } from './ui/Reveal';

export function StudentExperience() {
  return (
    <section id="platform" className="py-20 lg:py-28 bg-ink-100/60">
      <div className="container-page">
        <Reveal>
          <SectionHeader
            eyebrow="Student Experience"
            title="A clear, motivating view of every learner's day"
            description="Students always know what to do next, how far they've come, and what skills they're building."
          />
        </Reveal>

        <div className="mt-14 grid gap-5 lg:grid-cols-3">
          {/* Today's goal */}
          <Reveal>
            <div className="surface h-full p-6">
              <div className="flex items-center gap-2.5">
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
                  <Target className="h-5 w-5" />
                </span>
                <h3 className="font-display text-base font-bold text-ink-900">Today's Goal</h3>
              </div>
              <div className="mt-5 flex items-baseline gap-1">
                <span className="font-display text-4xl font-extrabold text-ink-900">30</span>
                <span className="text-lg font-semibold text-ink-500">minutes</span>
              </div>
              <p className="mt-2 text-sm text-ink-500">
                Focus on Algebra — Linear Equations
              </p>
              <div className="mt-4 flex items-center gap-2 rounded-lg bg-ink-50 p-2.5 text-xs text-ink-500">
                <Clock className="h-3.5 w-3.5" />
                <span>Started 9:40 AM</span>
              </div>
            </div>
          </Reveal>

          {/* Continue learning */}
          <Reveal delay={100}>
            <div className="surface h-full p-6">
              <div className="flex items-center gap-2.5">
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
                  <BookOpen className="h-5 w-5" />
                </span>
                <h3 className="font-display text-base font-bold text-ink-900">Continue Learning</h3>
              </div>
              <p className="mt-5 text-sm font-semibold text-ink-800">Mathematics</p>
              <p className="text-xs text-ink-500">Algebra — Linear Equations</p>
              <ProgressBar value={72} label="Progress" className="mt-3" />
              <button className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-brand-600 hover:text-brand-700">
                Resume <ArrowRight className="h-3.5 w-3.5" />
              </button>
            </div>
          </Reveal>

          {/* Recommended practice */}
          <Reveal delay={200}>
            <div className="surface h-full p-6">
              <div className="flex items-center gap-2.5">
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent-50 text-accent-600">
                  <FileText className="h-5 w-5" />
                </span>
                <h3 className="font-display text-base font-bold text-ink-900">Recommended Practice</h3>
              </div>
              <p className="mt-5 text-sm font-semibold text-ink-800">Word Problems</p>
              <p className="mt-1 text-xs text-ink-500">
                Based on your recent results, these will help close a gap.
              </p>
              <div className="mt-4 flex items-center gap-2">
                <Badge variant="warning">Recommended</Badge>
                <Badge variant="neutral">8 questions</Badge>
              </div>
            </div>
          </Reveal>
        </div>

        {/* Skills Lab + Streak row */}
        <div className="mt-5 grid gap-5 lg:grid-cols-3">
          <Reveal className="lg:col-span-2">
            <div className="surface h-full p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2.5">
                  <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-accent-50 text-accent-600">
                    <Code2 className="h-5 w-5" />
                  </span>
                  <h3 className="font-display text-base font-bold text-ink-900">Skills Lab</h3>
                </div>
                <Badge variant="accent">Web Creator</Badge>
              </div>
              <div className="mt-5 grid gap-4 sm:grid-cols-2">
                <div className="rounded-xl border border-ink-200 p-4">
                  <p className="text-sm font-semibold text-ink-800">HTML Foundations</p>
                  <div className="mt-2 flex items-center gap-2">
                    <Badge variant="success">Complete</Badge>
                  </div>
                </div>
                <div className="rounded-xl border border-ink-200 p-4">
                  <p className="text-sm font-semibold text-ink-800">CSS Styling</p>
                  <ProgressBar value={45} label="In progress" className="mt-2" />
                </div>
              </div>
              <button className="mt-4 inline-flex items-center gap-1.5 text-sm font-semibold text-accent-600 hover:text-accent-700">
                Continue CSS <ArrowRight className="h-3.5 w-3.5" />
              </button>
            </div>
          </Reveal>

          <Reveal delay={100}>
            <div className="surface h-full p-6">
              <div className="flex items-center gap-2.5">
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-orange-50 text-orange-600">
                  <Flame className="h-5 w-5" />
                </span>
                <h3 className="font-display text-base font-bold text-ink-900">Learning Streak</h3>
              </div>
              <div className="mt-5 flex items-baseline gap-1">
                <span className="font-display text-4xl font-extrabold text-ink-900">12</span>
                <span className="text-sm font-medium text-ink-500">days</span>
              </div>
              <div className="mt-4 flex gap-1.5">
                {['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d, i) => (
                  <div
                    key={i}
                    className={`flex h-7 flex-1 items-center justify-center rounded-md text-xs font-bold ${
                      i < 6 ? 'bg-orange-100 text-orange-600' : 'bg-ink-100 text-ink-400'
                    }`}
                  >
                    {d}
                  </div>
                ))}
              </div>
              <p className="mt-3 text-xs text-ink-500">Keep it up — you're on a roll!</p>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
