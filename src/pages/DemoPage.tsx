import { useState } from 'react';
import { DemoProvider, useDemo } from '@/demo/DemoContext';
import { DemoShell } from '@/demo/components/DemoShell';
import { StudentHomeView } from '@/demo/views/StudentHomeView';
import { LearningWorkspace } from '@/demo/components/LearningWorkspace';
import { NuruView } from '@/demo/views/NuruView';
import { SkillsLabView } from '@/demo/views/SkillsLabView';
import { TeacherView } from '@/demo/views/TeacherView';
import { AdminView } from '@/demo/views/AdminView';
import { DemoCompletion } from '@/demo/views/DemoCompletion';
import { DemoBookingModal } from '@/components/DemoBookingModal';
import { Badge } from '@/components/ui/Badge';

function DemoContent() {
  const { stage } = useDemo();
  const [bookingOpen, setBookingOpen] = useState(false);
  const content = stage === 'student' ? <StudentHomeView /> : stage === 'learning' ? <LearningWorkspace /> : stage === 'nuru' ? <NuruView /> : stage === 'skills' ? <SkillsLabView /> : stage === 'teacher' ? <TeacherView /> : stage === 'admin' ? <AdminView /> : <DemoCompletion />;
  return <><div className="mb-5 flex items-center justify-between gap-3"><Badge variant="neutral">Interactive demo — fictional data</Badge>{stage === 'complete' && <button onClick={() => setBookingOpen(true)} className="hidden rounded-xl border border-brand-300 bg-brand-50 px-3 py-2 text-xs font-bold text-brand-700 hover:bg-brand-100 sm:block">Book a School Demo</button>}</div>{content}<DemoBookingModal open={bookingOpen} onClose={() => setBookingOpen(false)} /></>;
}

export function DemoPage() {
  return <DemoProvider><DemoShell><DemoContent /></DemoShell></DemoProvider>;
}
