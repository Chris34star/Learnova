import { Sparkles, Send, BookOpen, RotateCcw, HelpCircle } from 'lucide-react';
import { SectionHeader } from './ui/SectionHeader';
import { Reveal } from './ui/Reveal';

const quickActions = [
  { icon: BookOpen, label: 'Explain this more simply' },
  { icon: RotateCcw, label: 'Give me another example' },
  { icon: HelpCircle, label: 'Why was my answer wrong?' },
];

export function NuruPreview() {
  return (
    <section id="nuru" className="py-20 lg:py-28 bg-ink-100/60">
      <div className="container-page">
        <Reveal>
          <SectionHeader
            eyebrow="Nuru"
            title="Help is always nearby."
            description="Nuru lives throughout the learning interface — not in a separate chatbot window. It offers contextual support exactly where the student is working."
          />
        </Reveal>

        <div className="mt-14 grid items-center gap-8 lg:grid-cols-2 lg:gap-12">
          {/* Visual example */}
          <Reveal>
            <div className="relative">
              {/* Learning workspace panel */}
              <div className="surface p-6">
                <div className="mb-4 flex items-center gap-2">
                  <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-50 text-brand-600">
                    <BookOpen className="h-4 w-4" />
                  </span>
                  <span className="text-sm font-semibold text-ink-800">
                    Algebra · Linear Equations
                  </span>
                </div>

                <div className="rounded-xl border border-ink-200 bg-ink-50 p-4">
                  <p className="text-xs font-medium text-ink-500">Question</p>
                  <p className="mt-1 text-sm text-ink-800">
                    Solve for <strong>x</strong>: 3x + 7 = 22
                  </p>
                </div>

                <div className="mt-4 rounded-xl border border-brand-200 bg-brand-50/50 p-4">
                  <div className="mb-2 flex items-center gap-2">
                    <span className="flex h-6 w-6 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-brand-700 text-white">
                      <Sparkles className="h-3 w-3" />
                    </span>
                    <span className="text-xs font-bold text-brand-700">Nuru</span>
                    <span className="text-xs text-ink-400">· contextual help</span>
                  </div>
                  <p className="text-sm text-ink-700">
                    To isolate <strong>x</strong>, first subtract 7 from both sides.
                    That gives <strong>3x = 15</strong>. Then divide both sides by 3,
                    so <strong>x = 5</strong>. Would you like to try a similar one?
                  </p>
                </div>

                {/* Quick actions */}
                <div className="mt-4 flex flex-wrap gap-2">
                  {quickActions.map((a) => (
                    <button
                      key={a.label}
                      className="inline-flex items-center gap-1.5 rounded-lg border border-ink-200 bg-white px-3 py-1.5 text-xs font-medium text-ink-600 transition-colors hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700"
                    >
                      <a.icon className="h-3.5 w-3.5" />
                      {a.label}
                    </button>
                  ))}
                </div>

                {/* Input */}
                <div className="mt-4 flex items-center gap-2 rounded-xl border border-ink-200 bg-white p-2 pl-4">
                  <input
                    type="text"
                    placeholder="Ask something about what you're learning..."
                    className="flex-1 bg-transparent text-sm text-ink-800 placeholder:text-ink-400 focus:outline-none"
                    readOnly
                  />
                  <button className="flex h-8 w-8 items-center justify-center rounded-lg bg-brand-600 text-white transition-colors hover:bg-brand-700">
                    <Send className="h-4 w-4" />
                  </button>
                </div>
              </div>

              {/* Floating collapsed Nuru indicator */}
              <div className="absolute -bottom-5 -right-3 flex items-center gap-2 rounded-full bg-white py-1.5 pl-1.5 pr-4 shadow-lift ring-1 ring-ink-200 animate-breathe">
                <span className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-brand-700 text-white">
                  <Sparkles className="h-4 w-4" />
                </span>
                <span className="text-sm font-semibold text-ink-700">Need help?</span>
              </div>
            </div>
          </Reveal>

          {/* Explanation */}
          <Reveal delay={150}>
            <div className="space-y-5">
              <div className="surface p-5">
                <div className="flex items-start gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
                    <Sparkles className="h-5 w-5" />
                  </span>
                  <div>
                    <h3 className="font-display text-base font-bold text-ink-900">
                      Embedded, not separate
                    </h3>
                    <p className="mt-1.5 text-sm text-ink-500">
                      Nuru appears alongside the learning material itself. Students
                      never leave their work to get help — the help comes to them.
                    </p>
                  </div>
                </div>
              </div>

              <div className="surface p-5">
                <div className="flex items-start gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-accent-50 text-accent-600">
                    <HelpCircle className="h-5 w-5" />
                  </span>
                  <div>
                    <h3 className="font-display text-base font-bold text-ink-900">
                      Contextual assistance
                    </h3>
                    <p className="mt-1.5 text-sm text-ink-500">
                      Quick actions like "Explain this more simply" or "Why was my
                      answer wrong?" give students a natural way to ask for exactly
                      the kind of help they need.
                    </p>
                  </div>
                </div>
              </div>

              <div className="surface p-5">
                <div className="flex items-start gap-3">
                  <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-ink-100 text-ink-600">
                    <BookOpen className="h-5 w-5" />
                  </span>
                  <div>
                    <h3 className="font-display text-base font-bold text-ink-900">
                      Learning support, not answers
                    </h3>
                    <p className="mt-1.5 text-sm text-ink-500">
                      Nuru is designed to guide understanding — helping students
                      think through problems rather than simply handing them
                      solutions.
                    </p>
                  </div>
                </div>
              </div>
            </div>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
