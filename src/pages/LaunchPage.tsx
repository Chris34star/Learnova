import { useState } from 'react';
import { Link } from 'react-router-dom';
import { Sparkles, ArrowLeft, Rocket, CheckCircle2, Mail } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { CountdownTimer } from '@/components/CountdownTimer';
import { Reveal } from '@/components/ui/Reveal';

type Role = 'School' | 'Student' | 'Parent';

export function LaunchPage() {
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [role, setRole] = useState<Role | ''>('');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
  };

  return (
    <div className="flex min-h-screen flex-col bg-ink-50">
      {/* Header */}
      <header className="border-b border-ink-200 bg-white/85 backdrop-blur-lg">
        <div className="container-page flex h-16 items-center justify-between">
          <Link to="/" className="flex items-center gap-2.5">
            <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-600 text-white">
              <Sparkles className="h-5 w-5" strokeWidth={2.5} />
            </span>
            <span className="font-display text-lg font-bold tracking-tight text-ink-900">
              Learnova
            </span>
          </Link>
          <Button to="/" variant="ghost" size="sm">
            <ArrowLeft className="h-4 w-4" />
            Back home
          </Button>
        </div>
      </header>

      <main className="flex flex-1 items-center justify-center px-5 py-16 lg:py-20">
        <div className="w-full max-w-3xl">
          {/* Hero */}
          <Reveal>
            <div className="text-center">
              <span className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                <Rocket className="h-3.5 w-3.5" />
                Launch Countdown
              </span>
              <h1 className="text-heading mt-5 text-4xl font-bold sm:text-5xl">
                Learnova is almost ready.
              </h1>
              <p className="text-body mt-4 text-lg">
                We're preparing the first public learning experience.
              </p>
            </div>
          </Reveal>

          {/* Countdown */}
          <Reveal delay={100} className="mt-10">
            <CountdownTimer />
          </Reveal>

          {/* Explore demo */}
          <Reveal delay={150} className="mt-6 text-center">
            <Button to="/demo" variant="outline" size="md">
              Explore the demo while you wait
            </Button>
          </Reveal>

          {/* Early access form */}
          <Reveal delay={200} className="mt-12">
            <div className="surface p-6 sm:p-8">
              {submitted ? (
                <div className="py-6 text-center">
                  <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-emerald-50 text-emerald-600">
                    <CheckCircle2 className="h-7 w-7" />
                  </div>
                  <h3 className="font-display text-xl font-bold text-ink-900">
                    You're on the list!
                  </h3>
                  <p className="mt-2 text-sm text-ink-500">
                    Thanks{name && `, ${name}`}! We'll notify you at{' '}
                    <span className="font-medium text-ink-700">{email || 'your email'}</span>{' '}
                    as soon as Learnova launches.
                  </p>
                  <button
                    onClick={() => {
                      setSubmitted(false);
                      setName('');
                      setEmail('');
                      setRole('');
                    }}
                    className="mt-4 text-sm font-semibold text-brand-600 hover:text-brand-700"
                  >
                    Submit another email
                  </button>
                </div>
              ) : (
                <>
                  <div className="mb-5 flex items-center gap-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
                      <Mail className="h-5 w-5" />
                    </span>
                    <div>
                      <h3 className="font-display text-lg font-bold text-ink-900">
                        Get early access
                      </h3>
                      <p className="text-xs text-ink-500">
                        Be among the first to experience Learnova.
                      </p>
                    </div>
                  </div>

                  <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                      <label htmlFor="launch-name" className="mb-1.5 block text-xs font-semibold text-ink-700">
                        Name
                      </label>
                      <input
                        id="launch-name"
                        type="text"
                        required
                        value={name}
                        onChange={(e) => setName(e.target.value)}
                        className="w-full rounded-xl border border-ink-200 bg-ink-50 px-3.5 py-2.5 text-sm text-ink-900 transition-all focus:border-brand-500 focus:bg-white focus:outline-none focus:ring-2 focus:ring-brand-500/15"
                        placeholder="Your name"
                      />
                    </div>
                    <div>
                      <label htmlFor="launch-email" className="mb-1.5 block text-xs font-semibold text-ink-700">
                        Email
                      </label>
                      <input
                        id="launch-email"
                        type="email"
                        required
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full rounded-xl border border-ink-200 bg-ink-50 px-3.5 py-2.5 text-sm text-ink-900 transition-all focus:border-brand-500 focus:bg-white focus:outline-none focus:ring-2 focus:ring-brand-500/15"
                        placeholder="you@email.com"
                      />
                    </div>
                    <div>
                      <label htmlFor="launch-role" className="mb-1.5 block text-xs font-semibold text-ink-700">
                        I am a...
                      </label>
                      <div className="grid grid-cols-3 gap-2">
                        {(['School', 'Student', 'Parent'] as Role[]).map((r) => (
                          <button
                            key={r}
                            type="button"
                            onClick={() => setRole(r)}
                            className={`rounded-xl border px-3 py-2.5 text-sm font-semibold transition-all ${
                              role === r
                                ? 'border-brand-500 bg-brand-50 text-brand-700 ring-2 ring-brand-500/15'
                                : 'border-ink-200 bg-ink-50 text-ink-600 hover:border-ink-300'
                            }`}
                          >
                            {r}
                          </button>
                        ))}
                      </div>
                    </div>
                    <Button type="submit" size="md" className="w-full">
                      Join the waitlist
                    </Button>
                  </form>
                </>
              )}
            </div>
          </Reveal>
        </div>
      </main>
    </div>
  );
}
