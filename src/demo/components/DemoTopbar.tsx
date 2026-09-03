import { Bell, Flame, Menu } from 'lucide-react';
import { studentDemoData, teacherDemoData, schoolDemoData } from '../data';
import type { DemoRole, DemoStage } from '../types';

export function DemoTopbar({ role, stage, onMenu, onExit }: { role: DemoRole; stage: DemoStage; onMenu: () => void; onExit: () => void }) {
  const isStudent = role === 'student';
  const studentTitles: Record<string, string> = { student: 'Home', learning: 'Smart Learning', nuru: 'Nuru Assistance', skills: 'Skills Lab' };
  const title = isStudent ? (studentTitles[stage] ?? 'Learning') : role === 'teacher' ? 'Teacher Insights' : 'School Admin';
  const profile = isStudent ? studentDemoData : role === 'teacher' ? teacherDemoData : schoolDemoData;
  return <header className="flex h-16 items-center justify-between border-b border-ink-200 bg-white px-4 sm:px-6"><div className="flex items-center gap-3"><button onClick={onMenu} className="rounded-lg p-2 text-ink-500 hover:bg-ink-100 lg:hidden" aria-label="Open navigation"><Menu className="h-5 w-5" /></button><div><p className="text-xs text-ink-400">Interactive demo</p><h1 className="font-display text-base font-bold text-ink-900 sm:text-lg">{title}</h1></div></div><div className="flex items-center gap-2 sm:gap-4"><span className="hidden items-center gap-1.5 rounded-full bg-accent-50 px-3 py-1.5 text-xs font-bold text-accent-700 sm:flex"><Flame className="h-3.5 w-3.5" />{isStudent ? `${studentDemoData.streak} day streak` : 'Demo view'}</span><button className="relative flex h-9 w-9 items-center justify-center rounded-lg text-ink-500 hover:bg-ink-100" aria-label="Notifications"><Bell className="h-4 w-4" /><span className="absolute right-2 top-2 h-1.5 w-1.5 rounded-full bg-brand-500" /></button><div className="flex h-9 w-9 items-center justify-center rounded-full bg-brand-100 text-xs font-bold text-brand-700" title={profile.name}>{isStudent ? 'AN' : role === 'teacher' ? 'MW' : 'PM'}</div><button onClick={onExit} className="hidden rounded-lg px-2.5 py-2 text-xs font-semibold text-ink-500 hover:bg-ink-100 hover:text-ink-800 sm:block">Exit Demo</button></div></header>;
}
