type Size = 'sm' | 'md' | 'lg';

const sizes: Record<Size, string> = {
  sm: 'h-1.5',
  md: 'h-2',
  lg: 'h-2.5',
};

export function ProgressBar({
  value,
  size = 'md',
  className = '',
  label,
}: {
  value: number;
  size?: Size;
  className?: string;
  label?: string;
}) {
  const clamped = Math.min(100, Math.max(0, value));
  return (
    <div className={`w-full ${className}`}>
      {label && (
        <div className="mb-1.5 flex items-center justify-between text-xs font-medium text-ink-500">
          <span>{label}</span>
          <span>{Math.round(clamped)}%</span>
        </div>
      )}
      <div
        className={`w-full overflow-hidden rounded-full bg-ink-200 ${sizes[size]}`}
        role="progressbar"
        aria-valuenow={Math.round(clamped)}
        aria-valuemin={0}
        aria-valuemax={100}
      >
        <div
          className="h-full rounded-full bg-gradient-to-r from-brand-500 to-brand-600 transition-all duration-700 ease-out"
          style={{ width: `${clamped}%` }}
        />
      </div>
    </div>
  );
}
