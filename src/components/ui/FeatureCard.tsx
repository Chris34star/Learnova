import type { ReactNode } from 'react';
import type { LucideIcon } from 'lucide-react';

export function FeatureCard({
  icon: Icon,
  title,
  children,
  className = '',
}: {
  icon: LucideIcon;
  title: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div
      className={`surface group p-6 transition-all duration-300 hover:shadow-lift hover:-translate-y-0.5 ${className}`}
    >
      <div className="mb-4 inline-flex h-11 w-11 items-center justify-center rounded-xl bg-brand-50 text-brand-600 transition-colors group-hover:bg-brand-100">
        <Icon className="h-5 w-5" strokeWidth={2} />
      </div>
      <h3 className="text-heading text-lg font-semibold">{title}</h3>
      <p className="text-body mt-2 text-sm">{children}</p>
    </div>
  );
}
