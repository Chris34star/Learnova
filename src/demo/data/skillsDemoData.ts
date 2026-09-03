import { BrainCircuit, Code2, Database, Rocket } from 'lucide-react';

export const pathwayData = [
  { name: 'Web Creator', description: 'Build and publish real websites.', modules: 7, icon: Code2, status: 'Active' },
  { name: 'AI Explorer', description: 'Understand AI through practical experiments.', modules: 5, icon: BrainCircuit, status: 'Coming soon' },
  { name: 'Young Entrepreneur', description: 'Turn ideas into simple business plans.', modules: 4, icon: Rocket, status: 'Explore pathway' },
  { name: 'Data Explorer', description: 'Find stories hidden in real data.', modules: 5, icon: Database, status: 'Explore pathway' },
];

export const webCreatorModules = [
  { title: 'How the Web Works', status: 'complete' },
  { title: 'HTML Foundations', status: 'complete' },
  { title: 'CSS Foundations', status: 'current' },
  { title: 'Responsive Design', status: 'locked' },
  { title: 'JavaScript Basics', status: 'locked' },
  { title: 'Build Your First Website', status: 'locked' },
  { title: 'Publish Your Project', status: 'locked' },
];
