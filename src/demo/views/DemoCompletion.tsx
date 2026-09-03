import { ArrowLeft, CheckCircle2, RotateCcw, Sparkles } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useDemo } from '../DemoContext';
import { Button } from '@/components/ui/Button';
import { Reveal } from '@/components/ui/Reveal';

export function DemoCompletion() {
  const navigate = useNavigate();
  const { reset } = useDemo();
  return <div className="mx-auto max-w-2xl py-8 text-center sm:py-16"><Reveal><div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-brand-600 text-white shadow-glow"><CheckCircle2 className="h-8 w-8" /></div><p className="text-eyebrow mt-6">Demo complete</p><h2 className="text-heading mt-3 text-4xl font-bold sm:text-5xl">You've explored Learnova.</h2><p className="text-body mx-auto mt-5 max-w-xl text-lg">Students receive personalized learning and practical skills while teachers and schools gain meaningful learning intelligence.</p><div className="mt-8 flex flex-col justify-center gap-3 sm:flex-row"><Button onClick={() => navigate('/')}><ArrowLeft className="h-4 w-4" />Return to Website</Button><Button to="/launch" variant="outline">Get Early Access</Button></div><button onClick={reset} className="mt-5 inline-flex items-center gap-2 text-sm font-semibold text-ink-500 hover:text-brand-600"><RotateCcw className="h-4 w-4" />Restart Demo</button><div className="mt-12 rounded-2xl border border-brand-200 bg-brand-50 p-5 text-left"><div className="flex items-start gap-3"><Sparkles className="mt-0.5 h-5 w-5 shrink-0 text-brand-600" /><div><p className="text-sm font-bold text-brand-900">Ready to see this in your school?</p><p className="mt-1 text-sm text-brand-800">Book a School Demo from the website to talk through your learning goals.</p></div></div></div></Reveal></div>;
}
