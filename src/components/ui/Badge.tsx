import type { ReactNode } from 'react';

type Variant = 'brand' | 'accent' | 'neutral' | 'success' | 'warning';

const variants: Record<Variant, string> = {
  brand: 'bg-brand-50 text-brand-700 border-brand-200',
  accent: 'bg-accent-50 text-accent-700 border-accent-200',
  neutral: 'bg-ink-100 text-ink-700 border-ink-200',
  success: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  warning: 'bg-orange-50 text-orange-700 border-orange-200',
};

export function Badge({
  children,
  variant = 'neutral',
  className = '',
}: {
  children: ReactNode;
  variant?: Variant;
  className?: string;
}) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-3 py-1 text-xs font-semibold ${variants[variant]} ${className}`}
    >
      {children}
    </span>
  );
}
