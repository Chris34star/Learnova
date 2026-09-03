import { createContext, useCallback, useContext, useMemo, useState, type ReactNode } from 'react';
import { getNuruResponse } from './data';
import type { DemoStage, DemoState, LessonMode } from './types';

const defaultDays = { Monday: true, Tuesday: true, Wednesday: true, Thursday: true, Friday: true, Saturday: true, Sunday: false };

const initialState: DemoState = {
  stage: 'student', role: 'student', lessonMode: 'lesson', answerStatus: 'idle', answer: '', mastery: 72,
  nuruQuestion: null, nuruResponse: null, nuruLoading: false, skillsStyle: 'clean', projectContinued: false,
  teacherStudentsVisible: false, assignmentState: 'idle', adminGrade: 'Grade 8', adminDays: defaultDays, adminContentOpen: false,
};

type DemoContextValue = DemoState & {
  setStage: (stage: DemoStage) => void;
  setLessonMode: (mode: LessonMode) => void;
  setAnswer: (answer: string) => void;
  checkAnswer: () => void;
  askNuru: (question: string) => void;
  clearNuru: () => void;
  setSkillsStyle: (style: DemoState['skillsStyle']) => void;
  continueProject: () => void;
  toggleTeacherStudents: () => void;
  assignPractice: () => void;
  setAdminGrade: (grade: string) => void;
  toggleAdminDay: (day: string) => void;
  toggleAdminContent: () => void;
  reset: () => void;
};

const DemoContext = createContext<DemoContextValue | null>(null);

export function DemoProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<DemoState>(initialState);
  const setStage = useCallback((stage: DemoStage) => setState((s) => ({ ...s, stage, role: stage === 'teacher' ? 'teacher' : stage === 'admin' ? 'admin' : 'student' })), []);
  const setLessonMode = useCallback((lessonMode: LessonMode) => setState((s) => ({ ...s, lessonMode })), []);
  const setAnswer = useCallback((answer: string) => setState((s) => ({ ...s, answer, answerStatus: 'idle' })), []);
  const checkAnswer = useCallback(() => setState((s) => ({ ...s, answerStatus: s.answer.trim() === '6' ? 'correct' : 'incorrect', mastery: s.answer.trim() === '6' ? Math.min(100, s.mastery + 3) : s.mastery })), []);
  const askNuru = useCallback((question: string) => {
    setState((s) => ({ ...s, nuruQuestion: question, nuruLoading: true, nuruResponse: null }));
    window.setTimeout(() => setState((s) => ({ ...s, nuruLoading: false, nuruResponse: getNuruResponse({ context: { subject: 'Mathematics', topic: 'Algebra', lesson: 'Linear Equations', studentState: s.lessonMode === 'practice' ? 'Practicing a weak area' : 'Learning a new concept' }, question }) })), 550);
  }, []);
  const clearNuru = useCallback(() => setState((s) => ({ ...s, nuruQuestion: null, nuruResponse: null })), []);
  const setSkillsStyle = useCallback((skillsStyle: DemoState['skillsStyle']) => setState((s) => ({ ...s, skillsStyle })), []);
  const continueProject = useCallback(() => setState((s) => ({ ...s, projectContinued: true })), []);
  const toggleTeacherStudents = useCallback(() => setState((s) => ({ ...s, teacherStudentsVisible: !s.teacherStudentsVisible })), []);
  const assignPractice = useCallback(() => setState((s) => ({ ...s, assignmentState: 'assigned' })), []);
  const setAdminGrade = useCallback((adminGrade: string) => setState((s) => ({ ...s, adminGrade })), []);
  const toggleAdminDay = useCallback((day: string) => setState((s) => ({ ...s, adminDays: { ...s.adminDays, [day]: !s.adminDays[day] } })), []);
  const toggleAdminContent = useCallback(() => setState((s) => ({ ...s, adminContentOpen: !s.adminContentOpen })), []);
  const reset = useCallback(() => setState(initialState), []);
  const value = useMemo(() => ({ ...state, setStage, setLessonMode, setAnswer, checkAnswer, askNuru, clearNuru, setSkillsStyle, continueProject, toggleTeacherStudents, assignPractice, setAdminGrade, toggleAdminDay, toggleAdminContent, reset }), [state, setStage, setLessonMode, setAnswer, checkAnswer, askNuru, clearNuru, setSkillsStyle, continueProject, toggleTeacherStudents, assignPractice, setAdminGrade, toggleAdminDay, toggleAdminContent, reset]);
  return <DemoContext.Provider value={value}>{children}</DemoContext.Provider>;
}

export function useDemo() {
  const context = useContext(DemoContext);
  if (!context) throw new Error('useDemo must be used within DemoProvider');
  return context;
}
