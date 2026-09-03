import { Rocket, ArrowRight } from 'lucide-react';
import { Button } from './ui/Button';
import { Reveal } from './ui/Reveal';

export function CTASection() {
  return (
    <section className="py-20 lg:py-28">
      <div className="container-page">
        <Reveal>
          <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-brand-700 via-brand-800 to-brand-900 px-6 py-16 text-center shadow-lift sm:px-12 lg:py-24">
            {/* Decorative glow */}
            <div className="absolute -top-20 right-0 h-72 w-72 rounded-full bg-brand-500/20 blur-3xl" />
            <div className="absolute -bottom-24 -left-10 h-72 w-72 rounded-full bg-accent-500/10 blur-3xl" />

            <div className="relative">
              <span className="inline-flex items-center gap-2 rounded-full bg-white/10 px-3 py-1 text-xs font-semibold text-brand-100 ring-1 ring-white/20">
                <Rocket className="h-3.5 w-3.5" />
                Interactive Demo
              </span>

              <h2 className="text-heading mx-auto mt-5 max-w-2xl text-3xl font-bold text-white sm:text-4xl lg:text-5xl">
                Don't just read about it. Try it.
              </h2>
              <p className="mx-auto mt-4 max-w-xl text-lg text-brand-100">
                Walk through a simulated student and school experience using an
                interactive product demo.
              </p>

              <div className="mt-8 flex justify-center">
                <Button
                  to="/demo"
                  size="lg"
                  className="bg-white text-brand-700 hover:bg-brand-50 active:bg-brand-100 shadow-lift"
                >
                  Launch Interactive Demo
                  <ArrowRight className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>
        </Reveal>
      </div>
    </section>
  );
}
