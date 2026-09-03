import { School, GraduationCap, ChartNoAxesCombined, ClipboardCheck } from 'lucide-react';
import { SectionHeader } from './ui/SectionHeader';
import { Reveal } from './ui/Reveal';

const steps = [
  {
    icon: School,
    title: 'School sets up students and learning programs',
    description: 'Administrators onboard students and assign learning paths in minutes.',
  },
  {
    icon: GraduationCap,
    title: 'Students learn and practice from school or home',
    description: 'Learners access their dashboard anywhere — classwork or homework.',
  },
  {
    icon: ChartNoAxesCombined,
    title: 'Learnova tracks progress and learning patterns',
    description: 'Every session feeds insight into mastery, effort and gaps.',
  },
  {
    icon: ClipboardCheck,
    title: 'Teachers receive actionable learning insights',
    description: 'Clear dashboards surface what needs attention — no manual analysis.',
  },
];

export function HowItWorks() {
  return (
    <section id="how-it-works" className="py-20 lg:py-28 bg-ink-100/60">
      <div className="container-page">
        <Reveal>
          <SectionHeader
            eyebrow="How It Works"
            title="From setup to insight in four steps"
          />
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {steps.map((s, i) => (
            <Reveal key={s.title} delay={i * 100}>
              <div className="relative h-full">
                <div className="surface h-full p-6">
                  <div className="mb-4 flex items-center gap-3">
                    <span className="flex h-11 w-11 items-center justify-center rounded-xl bg-brand-600 text-white font-display text-lg font-bold">
                      {i + 1}
                    </span>
                    <s.icon className="h-5 w-5 text-ink-400" />
                  </div>
                  <h3 className="font-display text-base font-bold text-ink-900">
                    {s.title}
                  </h3>
                  <p className="mt-2 text-sm text-ink-500">{s.description}</p>
                </div>
              </div>
            </Reveal>
          ))}
        </div>
      </div>
    </section>
  );
}
