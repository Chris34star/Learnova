import { ArrowRight, Calendar } from 'lucide-react';
import { Button } from './ui/Button';
import { ProductPreview } from './ProductPreview';
import { Reveal } from './ui/Reveal';

export function Hero({ onBookDemo }: { onBookDemo: () => void }) {
  return (
    <section className="relative overflow-hidden pt-28 pb-20 lg:pt-36 lg:pb-28">
      {/* Background decoration */}
      <div className="absolute inset-0 -z-10">
        <div className="absolute inset-0 bg-gradient-to-b from-brand-50/60 via-ink-50 to-ink-50" />
        <div className="absolute -top-24 right-0 h-96 w-96 rounded-full bg-brand-200/30 blur-3xl" />
        <div className="absolute top-40 -left-20 h-80 w-80 rounded-full bg-accent-200/20 blur-3xl" />
      </div>

      <div className="container-page grid items-center gap-12 lg:grid-cols-2 lg:gap-16">
        <div className="text-center lg:text-left">
          <Reveal>
            <span className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
              <span className="h-1.5 w-1.5 rounded-full bg-brand-500 animate-breathe" />
              A new kind of learning platform
            </span>
          </Reveal>

          <Reveal delay={100}>
            <h1 className="text-heading mt-5 text-4xl font-bold leading-[1.1] sm:text-5xl lg:text-6xl">
              Personalized learning that goes{' '}
              <span className="text-brand-600">beyond the classroom.</span>
            </h1>
          </Reveal>

          <Reveal delay={200}>
            <p className="text-body mt-5 text-lg lg:text-xl">
              Students practice academic subjects, get intelligent learning
              support, explore practical digital skills and continuously build
              their abilities while schools gain meaningful insight into their
              progress.
            </p>
          </Reveal>

          <Reveal delay={300}>
            <div className="mt-7 flex flex-col items-center gap-3 sm:flex-row lg:items-start">
              <Button to="/demo" size="lg" className="w-full sm:w-auto">
                Explore Interactive Demo
                <ArrowRight className="h-4 w-4" />
              </Button>
              <Button
                variant="outline"
                size="lg"
                className="w-full sm:w-auto"
                onClick={onBookDemo}
              >
                <Calendar className="h-4 w-4" />
                Book a School Demo
              </Button>
            </div>
          </Reveal>

          <Reveal delay={400}>
            <p className="mt-5 text-sm text-ink-500">
              Designed for modern schools, teachers and curious learners.
            </p>
          </Reveal>
        </div>

        <Reveal delay={200} className="lg:pl-4">
          <ProductPreview />
        </Reveal>
      </div>
    </section>
  );
}
