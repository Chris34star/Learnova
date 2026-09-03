import { BrowserRouter, Routes, Route, useLocation } from 'react-router-dom';
import { useEffect } from 'react';
import { LandingPage } from '@/pages/LandingPage';
import { DemoPage } from '@/pages/DemoPage';
import { LaunchPage } from '@/pages/LaunchPage';

function ScrollToTop() {
  const { pathname } = useLocation();
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [pathname]);
  return null;
}

function App() {
  return (
    <BrowserRouter>
      <ScrollToTop />
      <Routes>
        <Route path="/" element={<LandingPage />} />
        <Route path="/demo" element={<DemoPage />} />
        <Route path="/launch" element={<LaunchPage />} />
      </Routes>
    </BrowserRouter>
  );
}

export default App;
