export type DemoStage = 'student' | 'learning' | 'nuru' | 'skills' | 'teacher' | 'admin' | 'complete';
export type DemoRole = 'student' | 'teacher' | 'admin';
export type LessonMode = 'lesson' | 'practice';
export type AnswerStatus = 'idle' | 'correct' | 'incorrect';

export type NuruRequest = {
  context: {
    subject: string;
    topic: string;
    lesson: string;
    studentState: string;
  };
  question: string;
};

export type NuruResponse = {
  title: string;
  body: string;
  followUp: string;
  example?: string;
};

export type DemoState = {
  stage: DemoStage;
  role: DemoRole;
  lessonMode: LessonMode;
  answerStatus: AnswerStatus;
  answer: string;
  mastery: number;
  nuruQuestion: string | null;
  nuruResponse: NuruResponse | null;
  nuruLoading: boolean;
  skillsStyle: 'clean' | 'bold' | 'editorial';
  projectContinued: boolean;
  teacherStudentsVisible: boolean;
  assignmentState: 'idle' | 'assigned';
  adminGrade: string;
  adminDays: Record<string, boolean>;
  adminContentOpen: boolean;
};
