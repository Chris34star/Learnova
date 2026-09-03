import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { Menu, X, Sparkles } from 'lucide-react';
import { Button } from './ui/Button';

const navLinks = [
  { label: 'Platform', href: '#platform' },
  { label: 'Smart Learning', href: '#smart-learning' },
  { label: 'Skills Lab', href: '#skills-lab' },
  { label: 'For Schools', href: '#for-schools' },
];

export function Navbar({ onBookDemo }: { onBookDemo: () => void }) {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const location = useLocation();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 8);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => {
    setOpen(false);
  }, [location.pathname]);

  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 transition-all duration-300 ${
        scrolled
          ? 'border-b border-ink-200 bg-white/85 backdrop-blur-lg shadow-soft'
          : 'border-b border-transparent bg-transparent'
      }`}
    >
      <nav className="container-page flex h-16 items-center justify-between lg:h-18">
        <Link to="/" className="flex items-center gap-2.5" aria-label="Learnova home">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-600 text-white shadow-soft">
            <Sparkles className="h-5 w-5" strokeWidth={2.5} />
          </span>
          <span className="font-display text-lg font-bold tracking-tight text-ink-900">
            Learnova
          </span>
        </Link>

        <div className="hidden items-center gap-1 lg:flex">
          {navLinks.map((link) => (
            <a
              key={link.label}
              href={link.href}
              className="rounded-lg px-3.5 py-2 text-sm font-medium text-ink-600 transition-colors hover:bg-ink-100 hover:text-ink-900"
            >
              {link.label}
            </a>
          ))}
        </div>

        <div className="hidden items-center gap-2 lg:flex">
          <Button to="/demo" variant="outline" size="sm">
            Explore Demo
          </Button>
          <Button to="/launch" size="sm">
            Get Started
          </Button>
        </div>

        <button
          className="inline-flex h-10 w-10 items-center justify-center rounded-lg text-ink-700 hover:bg-ink-100 lg:hidden"
          onClick={() => setOpen((v) => !v)}
          aria-label={open ? 'Close menu' : 'Open menu'}
          aria-expanded={open}
        >
          {open ? <X className="h-5 w-5" /> : <Menu className="h-5 w-5" />}
        </button>
      </nav>

      {open && (
        <div className="animate-slide-down border-t border-ink-200 bg-white lg:hidden">
          <div className="container-page flex flex-col gap-1 py-4">
            {navLinks.map((link) => (
              <a
                key={link.label}
                href={link.href}
                className="rounded-lg px-3 py-2.5 text-sm font-medium text-ink-700 hover:bg-ink-100"
              >
                {link.label}
              </a>
            ))}
            <div className="mt-3 flex flex-col gap-2 border-t border-ink-200 pt-4">
              <Button to="/demo" variant="outline" size="md">
                Explore Demo
              </Button>
              <Button to="/launch" size="md">
                Get Started
              </Button>
              <button
                onClick={onBookDemo}
                className="inline-flex h-11 items-center justify-center rounded-xl border border-ink-300 px-5 text-sm font-semibold text-ink-800 hover:bg-ink-50"
              >
                Book a School Demo
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
