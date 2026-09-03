import { useEffect, useState } from 'react';
import { ArrowRight, BookOpen, HelpCircle, LoaderCircle, RotateCcw, Send, Sparkles, X } from 'lucide-react';
import { useDemo } from '../DemoContext';

const questions = ['Explain this more simply', 'Give me another example', 'Why was my answer wrong?'];

export function NuruAssistant() {
  const { askNuru, nuruLoading, nuruQuestion, stage, clearNuru } = useDemo();
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState('');
  const [attention, setAttention] = useState(false);

  useEffect(() => {
    if (stage === 'nuru') {
      setOpen(true);
      setAttention(true);
      const timeout = window.setTimeout(() => setAttention(false), 1800);
      return () => window.clearTimeout(timeout);
    }
    return undefined;
  }, [stage]);

  const submit = (question: string) => {
    if (question.trim()) {
      askNuru(question.trim());
      setInput('');
    }
  };

  const isStudentStage = stage === 'student' || stage === 'learning' || stage === 'nuru' || stage === 'skills';
  if (!isStudentStage) return null;

  return <div className={`fixed bottom-5 right-4 z-30 sm:right-6 ${attention ? 'animate-breathe' : ''}`}>
    {open && <div className="mb-3 w-[min(calc(100vw-2rem),22rem)] animate-scale-in rounded-2xl border border-ink-200 bg-white p-4 shadow-lift"><div className="flex items-center justify-between"><div className="flex items-center gap-2"><span className="flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-brand-700 text-white"><Sparkles className="h-4 w-4" /></span><div><p className="text-sm font-bold text-ink-900">Nuru</p><p className="text-[11px] text-ink-500">Learning assistant</p></div></div><button onClick={() => { setOpen(false); clearNuru(); }} className="rounded-lg p-1.5 text-ink-400 hover:bg-ink-100" aria-label="Close Nuru"><X className="h-4 w-4" /></button></div><div className="mt-3 flex items-center gap-2 rounded-xl border border-ink-200 bg-ink-50 p-2 pl-3"><input value={input} onChange={(e) => setInput(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && submit(input)} placeholder="Ask something about what you're learning..." className="min-w-0 flex-1 bg-transparent text-xs text-ink-800 placeholder:text-ink-400 focus:outline-none" /><button onClick={() => submit(input)} className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-brand-600 text-white hover:bg-brand-700" aria-label="Ask Nuru"><Send className="h-3.5 w-3.5" /></button></div><div className="mt-3"><p className="mb-2 text-[10px] font-bold uppercase tracking-wider text-ink-400">Try asking</p><div className="space-y-1">{questions.map((question, index) => { const Icon = index === 0 ? BookOpen : index === 1 ? RotateCcw : HelpCircle; return <button key={question} onClick={() => submit(question)} disabled={nuruLoading} className={`flex w-full items-center gap-2 rounded-lg px-2 py-2 text-left text-xs font-medium transition-colors hover:bg-brand-50 hover:text-brand-700 ${nuruQuestion === question ? 'bg-brand-50 text-brand-700' : 'text-ink-600'}`}><Icon className="h-3.5 w-3.5" />{question}<ArrowRight className="ml-auto h-3 w-3 opacity-50" /></button>; })}</div></div>{nuruLoading && <div className="mt-3 flex items-center gap-2 rounded-lg bg-ink-50 px-3 py-2 text-xs text-ink-500"><LoaderCircle className="h-3.5 w-3.5 animate-spin text-brand-600" />Nuru is thinking about your lesson...</div>}</div>}
    <button onClick={() => setOpen((value) => !value)} className="ml-auto flex items-center gap-2 rounded-full bg-white py-2 pl-2 pr-4 shadow-lift ring-1 ring-ink-200 transition-transform hover:-translate-y-0.5" aria-label="Open Nuru learning assistant"><span className="flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-brand-700 text-white"><Sparkles className="h-4 w-4" /></span><span className="text-xs font-bold text-ink-700">Need help?</span></button>
  </div>;
}
