import { Link } from 'react-router-dom';
import { Sparkles } from 'lucide-react';

const productLinks = [
  { label: 'Smart Learning', href: '#smart-learning' },
  { label: 'Skills Lab', href: '#skills-lab' },
  { label: 'Nuru', href: '#nuru' },
  { label: 'Schools', href: '#for-schools' },
];

const companyLinks = [
  { label: 'About', href: '#' },
  { label: 'Contact', href: '#' },
];

const legalLinks = [
  { label: 'Privacy', href: '#' },
  { label: 'Terms', href: '#' },
];

export function Footer() {
  return (
    <footer className="border-t border-ink-200 bg-white">
      <div className="container-page py-14">
        <div className="grid gap-10 lg:grid-cols-5">
          {/* Brand */}
          <div className="lg:col-span-2">
            <Link to="/" className="flex items-center gap-2.5">
              <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-600 text-white">
                <Sparkles className="h-5 w-5" strokeWidth={2.5} />
              </span>
              <span className="font-display text-lg font-bold tracking-tight text-ink-900">
                Learnova
              </span>
            </Link>
            <p className="mt-4 max-w-xs text-sm text-ink-500">
              Learn smarter. Build real skills. A modern learning platform for
              students, teachers and schools.
            </p>
          </div>

          {/* Product */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-ink-400">
              Product
            </p>
            <ul className="mt-4 space-y-2.5">
              {productLinks.map((l) => (
                <li key={l.label}>
                  <a
                    href={l.href}
                    className="text-sm text-ink-600 transition-colors hover:text-brand-600"
                  >
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Company */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-ink-400">
              Company
            </p>
            <ul className="mt-4 space-y-2.5">
              {companyLinks.map((l) => (
                <li key={l.label}>
                  <a
                    href={l.href}
                    className="text-sm text-ink-600 transition-colors hover:text-brand-600"
                  >
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>

          {/* Legal */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-ink-400">
              Legal
            </p>
            <ul className="mt-4 space-y-2.5">
              {legalLinks.map((l) => (
                <li key={l.label}>
                  <a
                    href={l.href}
                    className="text-sm text-ink-600 transition-colors hover:text-brand-600"
                  >
                    {l.label}
                  </a>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="mt-12 border-t border-ink-200 pt-6">
          <p className="text-center text-sm text-ink-500">
            Built for the future of learning.
          </p>
        </div>
      </div>
    </footer>
  );
}
