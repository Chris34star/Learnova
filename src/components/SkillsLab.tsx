import { Code2, BrainCircuit, Rocket, Database, FolderGit2 } from 'lucide-react';
import { SectionHeader } from './ui/SectionHeader';
import { Badge } from './ui/Badge';
import { Reveal } from './ui/Reveal';

type Pathway = {
  icon: typeof Code2;
  title: string;
  description: string;
  modules: number;
  progress: string;
  accent: string;
};

const pathways: Pathway[] = [
  {
    icon: Code2,
    title: 'Web Creator',
    description: 'Build and publish real websites using HTML, CSS and JavaScript.',
    modules: 6,
    progress: 'Project-based',
    accent: 'brand',
  },
  {
    icon: BrainCircuit,
    title: 'AI Explorer',
    description: 'Understand how AI works and experiment with practical tools.',
    modules: 5,
    progress: 'Coming soon',
    accent: 'accent',
  },
  {
    icon: Rocket,
    title: 'Young Entrepreneur',
    description: 'Turn an idea into a simple business plan and pitch it.',
    modules: 4,
    progress: 'Coming soon',
    accent: 'neutral',
  },
  {
    icon: Database,
    title: 'Data Explorer',
    description: 'Learn to read, organize and tell stories with data.',
    modules: 5,
    progress: 'Coming soon',
    accent: 'neutral',
  },
];

const accentMap: Record<string, string> = {
  brand: 'bg-brand-50 text-brand-600',
  accent: 'bg-accent-50 text-accent-600',
  neutral: 'bg-ink-100 text-ink-600',
};

export function SkillsLab() {
  return (
    <section id="skills-lab" className="py-20 lg:py-28">
      <div className="container-page">
        <Reveal>
          <SectionHeader
            eyebrow="Skills Lab"
            title="School teaches the curriculum. Skills Lab helps students explore what's next."
            description="Skills Lab is a project-oriented space where students apply what they know to real, creative work — from building a first website to exploring AI."
          />
        </Reveal>

        <div className="mt-14 grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {pathways.map((p, i) => (
            <Reveal key={p.title} delay={i * 100}>
              <div className="surface group h-full p-6 transition-all duration-300 hover:shadow-lift hover:-translate-y-0.5">
                <div
                  className={`mb-4 inline-flex h-12 w-12 items-center justify-center rounded-xl ${accentMap[p.accent]}`}
                >
                  <p.icon className="h-6 w-6" />
                </div>
                <h3 className="font-display text-lg font-bold text-ink-900">{p.title}</h3>
                <p className="mt-2 text-sm text-ink-500">{p.description}</p>
                <div className="mt-4 flex items-center justify-between border-t border-ink-100 pt-3">
                  <span className="text-xs font-medium text-ink-500">
                    {p.modules} modules
                  </span>
                  <Badge variant={p.accent === 'brand' ? 'brand' : p.accent === 'accent' ? 'accent' : 'neutral'}>
                    {p.progress}
                  </Badge>
                </div>
              </div>
            </Reveal>
          ))}
        </div>

        {/* Example project */}
        <Reveal delay={200}>
          <div className="mt-8 surface flex flex-col items-start gap-4 p-6 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex items-center gap-4">
              <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-brand-600 text-white">
                <FolderGit2 className="h-6 w-6" />
              </span>
              <div>
                <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">
                  Example project
                </p>
                <p className="font-display text-lg font-bold text-ink-900">
                  Build and publish your first website.
                </p>
              </div>
            </div>
            <Badge variant="brand">Skills Lab · Web Creator</Badge>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
