import { useEffect, useState } from 'react';
import { X, CheckCircle2, Calendar } from 'lucide-react';
import { Button } from './ui/Button';

type FormData = {
  name: string;
  school: string;
  role: string;
  contact: string;
  message: string;
};

const empty: FormData = { name: '', school: '', role: '', contact: '', message: '' };

export function DemoBookingModal({
  open,
  onClose,
}: {
  open: boolean;
  onClose: () => void;
}) {
  const [form, setForm] = useState<FormData>(empty);
  const [submitted, setSubmitted] = useState(false);

  useEffect(() => {
    if (!open) {
      const t = setTimeout(() => {
        setForm(empty);
        setSubmitted(false);
      }, 300);
      return () => clearTimeout(t);
    }
  }, [open]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (open) document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  if (!open) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmitted(true);
  };

  return (
    <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-ink-950/40 backdrop-blur-sm animate-fade-in"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Modal */}
      <div
        className="relative z-10 w-full max-w-md animate-scale-in rounded-2xl bg-white p-6 shadow-lift sm:p-8"
        role="dialog"
        aria-modal="true"
        aria-labelledby="demo-booking-title"
      >
        <button
          onClick={onClose}
          className="absolute right-4 top-4 flex h-9 w-9 items-center justify-center rounded-lg text-ink-400 hover:bg-ink-100 hover:text-ink-700"
          aria-label="Close"
        >
          <X className="h-5 w-5" />
        </button>

        {submitted ? (
          <div className="py-6 text-center">
            <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-emerald-50 text-emerald-600">
              <CheckCircle2 className="h-7 w-7" />
            </div>
            <h3 className="font-display text-xl font-bold text-ink-900">
              Request received!
            </h3>
            <p className="mt-2 text-sm text-ink-500">
              Thanks, {form.name || 'there'}. Our team will reach out to{' '}
              {form.school || 'your school'} shortly to schedule a personalized demo.
            </p>
            <Button onClick={onClose} className="mt-6 w-full">
              Done
            </Button>
          </div>
        ) : (
          <>
            <div className="mb-5 flex items-center gap-3">
              <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-brand-50 text-brand-600">
                <Calendar className="h-5 w-5" />
              </span>
              <div>
                <h3 id="demo-booking-title" className="font-display text-lg font-bold text-ink-900">
                  Book a School Demo
                </h3>
                <p className="text-xs text-ink-500">We'll be in touch within 48 hours.</p>
              </div>
            </div>

            <form onSubmit={handleSubmit} className="space-y-4">
              <Field label="Name" htmlFor="name">
                <input
                  id="name"
                  type="text"
                  required
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="input"
                  placeholder="Jane Doe"
                />
              </Field>
              <Field label="School" htmlFor="school">
                <input
                  id="school"
                  type="text"
                  required
                  value={form.school}
                  onChange={(e) => setForm({ ...form, school: e.target.value })}
                  className="input"
                  placeholder="Greenfield Academy"
                />
              </Field>
              <Field label="Role" htmlFor="role">
                <select
                  id="role"
                  required
                  value={form.role}
                  onChange={(e) => setForm({ ...form, role: e.target.value })}
                  className="input"
                >
                  <option value="" disabled>Select your role</option>
                  <option value="teacher">Teacher</option>
                  <option value="admin">Administrator</option>
                  <option value="principal">Principal</option>
                  <option value="parent">Parent</option>
                  <option value="other">Other</option>
                </select>
              </Field>
              <Field label="Phone / Email" htmlFor="contact">
                <input
                  id="contact"
                  type="text"
                  required
                  value={form.contact}
                  onChange={(e) => setForm({ ...form, contact: e.target.value })}
                  className="input"
                  placeholder="jane@greenfield.edu"
                />
              </Field>
              <Field label="Message" htmlFor="message">
                <textarea
                  id="message"
                  rows={3}
                  value={form.message}
                  onChange={(e) => setForm({ ...form, message: e.target.value })}
                  className="input resize-none"
                  placeholder="Tell us what you'd like to see..."
                />
              </Field>

              <Button type="submit" size="md" className="w-full">
                Request Demo
              </Button>
            </form>
          </>
        )}
      </div>

      <style>{`
        .input {
          width: 100%;
          border-radius: 0.75rem;
          border: 1px solid #e7e5e4;
          background: #fafaf9;
          padding: 0.625rem 0.875rem;
          font-size: 0.875rem;
          color: #1c1917;
          transition: border-color 0.2s, box-shadow 0.2s;
        }
        .input:focus {
          outline: none;
          border-color: #0d9488;
          box-shadow: 0 0 0 3px rgb(13 148 136 / 0.15);
        }
        .input::placeholder { color: #a8a29e; }
      `}</style>
    </div>
  );
}

function Field({
  label,
  htmlFor,
  children,
}: {
  label: string;
  htmlFor: string;
  children: React.ReactNode;
}) {
  return (
    <div>
      <label htmlFor={htmlFor} className="mb-1.5 block text-xs font-semibold text-ink-700">
        {label}
      </label>
      {children}
    </div>
  );
}
