import type { ReactNode } from 'react';

export function SectionHeader({
  eyebrow,
  title,
  description,
  align = 'center',
  className = '',
}: {
  eyebrow?: string;
  title: ReactNode;
  description?: ReactNode;
  align?: 'center' | 'left';
  className?: string;
}) {
  return (
    <div
      className={`max-w-2xl ${
        align === 'center' ? 'mx-auto text-center' : 'text-left'
      } ${className}`}
    >
      {eyebrow && <p className="text-eyebrow mb-3">{eyebrow}</p>}
      <h2 className="text-heading text-3xl font-bold leading-tight sm:text-4xl">
        {title}
      </h2>
      {description && (
        <p className="text-body mt-4 text-lg">{description}</p>
      )}
    </div>
  );
}
