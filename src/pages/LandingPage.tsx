import { useState } from 'react';
import { Navbar } from '@/components/Navbar';
import { Hero } from '@/components/Hero';
import { SmartLearning } from '@/components/SmartLearning';
import { StudentExperience } from '@/components/StudentExperience';
import { SkillsLab } from '@/components/SkillsLab';
import { NuruPreview } from '@/components/NuruPreview';
import { SchoolDashboardPreview } from '@/components/SchoolDashboardPreview';
import { HowItWorks } from '@/components/HowItWorks';
import { CTASection } from '@/components/CTASection';
import { Footer } from '@/components/Footer';
import { DemoBookingModal } from '@/components/DemoBookingModal';

export function LandingPage() {
  const [demoOpen, setDemoOpen] = useState(false);

  return (
    <div className="min-h-screen bg-ink-50">
      <Navbar onBookDemo={() => setDemoOpen(true)} />
      <main>
        <Hero onBookDemo={() => setDemoOpen(true)} />
        <SmartLearning />
        <StudentExperience />
        <SkillsLab />
        <NuruPreview />
        <SchoolDashboardPreview />
        <HowItWorks />
        <CTASection />
      </main>
      <Footer />
      <DemoBookingModal open={demoOpen} onClose={() => setDemoOpen(false)} />
    </div>
  );
}
