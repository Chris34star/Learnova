import { BookOpen, PencilRuler, ChartNoAxesCombined, LifeBuoy, TrendingUp, ArrowRight } from 'lucide-react';
import { SectionHeader } from './ui/SectionHeader';
import { Reveal } from './ui/Reveal';

const steps = [
  {
    icon: BookOpen,
    title: 'Learn',
    description: 'Students engage with structured lessons across core academic subjects.',
  },
  {
    icon: PencilRuler,
    title: 'Practice',
    description: 'Targeted exercises reinforce understanding and surface gaps.',
  },
  {
    icon: ChartNoAxesCombined,
    title: 'Understand Weaknesses',
    description: 'The system identifies specific topics where a student struggles.',
  },
  {
    icon: LifeBuoy,
    title: 'Get Targeted Support',
    description: 'Nuru provides contextual help right where the student is learning.',
  },
  {
    icon: TrendingUp,
    title: 'Improve',
    description: 'Practice adapts around progress, focusing effort where it matters most.',
  },
];

export function SmartLearning() {
  return (
    <section id="smart-learning" className="py-20 lg:py-28">
      <div className="container-page">
        <Reveal>
          <SectionHeader
            eyebrow="Smart Learning"
            title="A learning loop that adapts to each student"
            description="Rather than giving students endless random questions, Learnova continuously adjusts practice around what each learner actually needs."
          />
        </Reveal>

        <div className="mt-14">
          <div className="flex flex-col items-stretch gap-4 lg:flex-row lg:items-center">
            {steps.map((step, i) => (
              <Reveal key={step.title} delay={i * 100} className="flex-1">
                <div className="surface group relative h-full p-5 transition-all duration-300 hover:shadow-lift hover:-translate-y-0.5">
                  <div className="mb-3 flex items-center gap-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-600 transition-colors group-hover:bg-brand-100">
                      <step.icon className="h-5 w-5" />
                    </span>
                    <span className="text-xs font-bold text-ink-400">
                      0{i + 1}
                    </span>
                  </div>
                  <h3 className="font-display text-base font-bold text-ink-900">
                    {step.title}
                  </h3>
                  <p className="mt-1.5 text-sm text-ink-500">{step.description}</p>

                  {i < steps.length - 1 && (
                    <div className="absolute -right-3 top-1/2 hidden -translate-y-1/2 text-ink-300 lg:block">
                      <ArrowRight className="h-5 w-5" />
                    </div>
                  )}
                </div>
              </Reveal>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
