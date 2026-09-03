import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';
import { useEffect } from 'react';
import { LandingPage } from '@/pages/LandingPage';
import { DemoPage } from '@/pages/DemoPage';
import { LaunchPage } from '@/pages/LaunchPage';
import { AuthProvider } from '@/auth/AuthContext';
import { ProtectedRoute,RoleRoute,AuthLanding } from '@/auth/Routes';
import { LoginPage,ForgotPasswordPage,ResetPasswordPage } from '@/pages/auth/AuthPages';
import { StudentShell,TeacherShell,SchoolShell,PlatformShell } from '@/layouts/shells';
import { TeacherOverview,SchoolOverview,Placeholder } from '@/pages/shared';
import {CourseCatalog,CourseOverview,ExplorePage,LessonWorkspace,ModuleOverview,ProgressPage,StudentDashboard} from '@/pages/student/LearningPages';
import {SchoolLearningAnalytics,TeacherStudentLearning} from '@/pages/insights/LearningVisibility';
import { StudentsPage,TeachersPage,GradesPage,ClassesPage,SubjectsPage } from '@/pages/school/ManagementPages';
import { SettingsPage } from '@/pages/school/SettingsPage';
import { OnboardingPage } from '@/pages/school/OnboardingPage';
import { PlatformOverview,SchoolsPage } from '@/pages/platform/PlatformPages';
import { ContentEditorPage,PlatformContentPage,ProposalsPage,ReviewQueuePage,SchoolContentPage,TeacherContentPage } from '@/pages/content/ContentPages';
import { NuruStudioPage } from '@/pages/content/NuruStudioPage';
import { ContentOpportunitiesPage } from '@/pages/content/ContentOpportunitiesPage';

function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

function App() {
  return (
    <BrowserRouter><AuthProvider>
      <ScrollToTop />
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/demo" element={<DemoPage />} />
        <Route path="/launch" element={<LaunchPage />} />
        <Route path="/login" element={<LoginPage/>}/><Route path="/forgot-password" element={<ForgotPasswordPage/>}/><Route path="/reset-password" element={<ResetPasswordPage/>}/>
        <Route element={<ProtectedRoute/>}><Route path="/auth" element={<AuthLanding/>}/>
          <Route element={<RoleRoute allow="student"/>}><Route path="/app" element={<StudentShell/>}><Route index element={<StudentDashboard/>}/><Route path="learn" element={<CourseCatalog/>}/><Route path="course/:courseId" element={<CourseOverview/>}/><Route path="course/:courseId/module/:moduleId" element={<ModuleOverview/>}/><Route path="lesson/:lessonId" element={<LessonWorkspace/>}/><Route path="practice" element={<Placeholder title="Practice" stage="Stage 7 assessment engine"/>}/><Route path="skills" element={<CourseCatalog family="skills"/>}/><Route path="progress" element={<ProgressPage/>}/><Route path="explore" element={<ExplorePage/>}/></Route></Route>
          <Route element={<RoleRoute allow="teacher"/>}><Route path="/teacher" element={<TeacherShell/>}><Route index element={<TeacherOverview/>}/><Route path="classes" element={<TeacherOverview/>}/><Route path="students" element={<StudentsPage/>}/><Route path="students/:studentId" element={<TeacherStudentLearning/>}/><Route path="content" element={<TeacherContentPage/>}/><Route path="content/studio" element={<NuruStudioPage/>}/><Route path="assignments" element={<Placeholder title="Assignments" stage="a later learning stage"/>}/><Route path="insights" element={<Placeholder title="Insights" stage="advanced analytics"/>}/></Route></Route>
          <Route element={<RoleRoute allow="school_admin"/>}><Route path="/school" element={<SchoolShell/>}><Route index element={<SchoolOverview/>}/><Route path="onboarding" element={<OnboardingPage/>}/><Route path="students" element={<StudentsPage/>}/><Route path="teachers" element={<TeachersPage/>}/><Route path="classes" element={<ClassesPage/>}/><Route path="grades" element={<GradesPage/>}/><Route path="subjects" element={<SubjectsPage/>}/><Route path="settings" element={<SettingsPage/>}/><Route path="schedule" element={<Placeholder title="Learning schedule" stage="Stage 7"/>}/><Route path="content" element={<SchoolContentPage/>}/><Route path="content/editor" element={<ContentEditorPage/>}/><Route path="content/studio" element={<NuruStudioPage/>}/><Route path="content/opportunities" element={<ContentOpportunitiesPage/>}/><Route path="content/review" element={<ReviewQueuePage/>}/><Route path="analytics" element={<SchoolLearningAnalytics/>}/></Route></Route>
          <Route element={<RoleRoute allow="platform_admin"/>}><Route path="/platform" element={<PlatformShell/>}><Route index element={<PlatformOverview/>}/><Route path="schools" element={<SchoolsPage/>}/><Route path="content" element={<PlatformContentPage/>}/><Route path="content/editor" element={<ContentEditorPage/>}/><Route path="content/studio" element={<NuruStudioPage/>}/><Route path="content/opportunities" element={<ContentOpportunitiesPage/>}/><Route path="content/proposals" element={<ProposalsPage/>}/><Route path="usage" element={<Placeholder title="Usage" stage="advanced analytics"/>}/><Route path="settings" element={<Placeholder title="Platform settings" stage="future platform configuration"/>}/></Route></Route>
        </Route>
      </Routes>
    </AuthProvider></BrowserRouter>
  );
}

export default App;
