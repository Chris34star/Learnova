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
import {CourseCatalog,CourseOverview,LessonWorkspace,ModuleOverview,ProgressPage,StudentDashboard} from '@/pages/student/LearningPages';
import {TeacherStudentLearning} from '@/pages/insights/LearningVisibility';
import { StudentsPage,TeachersPage,GradesPage,ClassesPage,SubjectsPage } from '@/pages/school/ManagementPages';
import { SettingsPage } from '@/pages/school/SettingsPage';
import { OnboardingPage } from '@/pages/school/OnboardingPage';
import { PlatformOverview,SchoolsPage } from '@/pages/platform/PlatformPages';
import { ContentEditorPage,PlatformContentPage,ProposalsPage,ReviewQueuePage,SchoolContentPage,TeacherContentPage } from '@/pages/content/ContentPages';
import { NuruStudioPage } from '@/pages/content/NuruStudioPage';
import { ContentOpportunitiesPage } from '@/pages/content/ContentOpportunitiesPage';
import { PracticePage } from '@/pages/student/PracticePage';
import { ExploreNextPage,InterestsPage } from '@/pages/student/ExplorePages';
import { PathwayManagementPage,RecommendLearningPage } from '@/pages/pathways/PathwayPages';
import {PortfolioPage,ProjectWorkspace,SkillsLabHome,SkillsPathwayPage} from '@/pages/student/SkillsLabPages';
import {TeacherProjectsPage} from '@/pages/teacher/ProjectPages';
import {LearningScheduleSettings,SchoolIntelligencePage,StudentSchedule,TeacherClassInsights,TeacherClasses} from '@/pages/insights/Stage11Pages';

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
          <Route element={<RoleRoute allow="student"/>}><Route path="/app" element={<StudentShell/>}><Route index element={<StudentDashboard/>}/><Route path="schedule" element={<StudentSchedule/>}/><Route path="learn" element={<CourseCatalog/>}/><Route path="course/:courseId" element={<CourseOverview/>}/><Route path="course/:courseId/module/:moduleId" element={<ModuleOverview/>}/><Route path="lesson/:lessonId" element={<LessonWorkspace/>}/><Route path="practice" element={<PracticePage/>}/><Route path="skills" element={<SkillsLabHome/>}/><Route path="skills/:pathwayId" element={<SkillsPathwayPage/>}/><Route path="project/:studentProjectId" element={<ProjectWorkspace/>}/><Route path="portfolio" element={<PortfolioPage/>}/><Route path="progress" element={<ProgressPage/>}/><Route path="explore" element={<ExploreNextPage/>}/><Route path="interests" element={<InterestsPage/>}/></Route></Route>
          <Route element={<RoleRoute allow="teacher"/>}><Route path="/teacher" element={<TeacherShell/>}><Route index element={<TeacherOverview/>}/><Route path="classes" element={<TeacherClasses/>}/><Route path="classes/:classId/insights" element={<TeacherClassInsights/>}/><Route path="students" element={<StudentsPage/>}/><Route path="students/:studentId" element={<TeacherStudentLearning/>}/><Route path="content" element={<TeacherContentPage/>}/><Route path="content/studio" element={<NuruStudioPage/>}/><Route path="assignments" element={<Placeholder title="Assignments" stage="Stage 10 assignment architecture"/>}/><Route path="projects" element={<TeacherProjectsPage/>}/><Route path="recommend" element={<RecommendLearningPage/>}/><Route path="insights" element={<TeacherClasses/>}/></Route></Route>
          <Route element={<RoleRoute allow="school_admin"/>}><Route path="/school" element={<SchoolShell/>}><Route index element={<SchoolOverview/>}/><Route path="onboarding" element={<OnboardingPage/>}/><Route path="students" element={<StudentsPage/>}/><Route path="teachers" element={<TeachersPage/>}/><Route path="classes" element={<ClassesPage/>}/><Route path="grades" element={<GradesPage/>}/><Route path="subjects" element={<SubjectsPage/>}/><Route path="settings" element={<SettingsPage/>}/><Route path="schedule" element={<LearningScheduleSettings/>}/><Route path="content" element={<SchoolContentPage/>}/><Route path="content/editor" element={<ContentEditorPage/>}/><Route path="content/studio" element={<NuruStudioPage/>}/><Route path="content/opportunities" element={<ContentOpportunitiesPage/>}/><Route path="content/review" element={<ReviewQueuePage/>}/><Route path="analytics" element={<SchoolIntelligencePage/>}/><Route path="pathways" element={<PathwayManagementPage/>}/></Route></Route>
          <Route element={<RoleRoute allow="platform_admin"/>}><Route path="/platform" element={<PlatformShell/>}><Route index element={<PlatformOverview/>}/><Route path="schools" element={<SchoolsPage/>}/><Route path="content" element={<PlatformContentPage/>}/><Route path="content/editor" element={<ContentEditorPage/>}/><Route path="content/studio" element={<NuruStudioPage/>}/><Route path="content/opportunities" element={<ContentOpportunitiesPage/>}/><Route path="content/proposals" element={<ProposalsPage/>}/><Route path="pathways" element={<PathwayManagementPage platform/>}/><Route path="usage" element={<Placeholder title="Usage" stage="advanced analytics"/>}/><Route path="settings" element={<Placeholder title="Platform settings" stage="future platform configuration"/>}/></Route></Route>
        </Route>
      </Routes>
    </AuthProvider></BrowserRouter>
  );
}

export default App;
