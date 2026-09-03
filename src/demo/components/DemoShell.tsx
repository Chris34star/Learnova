import { useState, type ReactNode } from 'react';
import { useNavigate } from 'react-router-dom';
import { DemoProgress } from './DemoProgress';
import { DemoTopbar } from './DemoTopbar';
import { NuruAssistant } from './NuruAssistant';
import { RoleSidebar } from './RoleSidebar';
import { StudentSidebar } from './StudentSidebar';
import { useDemo } from '../DemoContext';
import type { DemoStage } from '../types';

export function DemoShell({ children }: { children: ReactNode }) {
  const navigate = useNavigate();
  const { stage, role, setStage } = useDemo();
  const [menuOpen, setMenuOpen] = useState(false);
  const stages: DemoStage[] = ['student', 'learning', 'nuru', 'skills', 'teacher', 'admin', 'complete'];
  const current = stages.indexOf(stage);
  const goNext = () => setStage(current >= 5 ? 'complete' : stages[Math.min(current + 1, stages.length - 2)]);
  const goPrevious = () => setStage(stage === 'complete' ? 'admin' : stages[Math.max(current - 1, 0)]);
  const isStudent = role === 'student';
  return <div className="min-h-screen bg-ink-50"><div className="flex min-h-screen"><div className="hidden lg:block">{isStudent ? <StudentSidebar stage={stage} onStage={setStage} open={false} onClose={() => undefined} /> : <RoleSidebar role={role} open={false} onClose={() => undefined} />}</div><div className="lg:hidden">{isStudent ? <StudentSidebar stage={stage} onStage={setStage} open={menuOpen} onClose={() => setMenuOpen(false)} /> : <RoleSidebar role={role} open={menuOpen} onClose={() => setMenuOpen(false)} />}</div><div className="min-w-0 flex-1"><DemoTopbar role={role} stage={stage} onMenu={() => setMenuOpen(true)} onExit={() => navigate('/')} /><DemoProgress stage={stage} onStage={setStage} onNext={goNext} onPrevious={goPrevious} /><main className="container-page py-7 pb-28 sm:py-9">{children}</main></div></div><NuruAssistant /></div>;
}
