import { useState } from 'react';
import { AlertTriangle, ArrowRight, CheckCircle2, FileText, Users, X } from 'lucide-react';
import { teacherDemoData } from '../data';
import { useDemo } from '../DemoContext';
import { Badge } from '@/components/ui/Badge';
import { ProgressBar } from '@/components/ui/ProgressBar';
import { Reveal } from '@/components/ui/Reveal';

const statusVariant: Record<string, 'warning' | 'accent' | 'success'> = {
  'Needs practice': 'warning',
  'Improving': 'accent',
  'On track': 'success',
};

export function TeacherView() {
  const { teacherStudentsVisible, toggleTeacherStudents, assignmentState, assignPractice } = useDemo();
  const [assignOpen, setAssignOpen] = useState(false);

  return (
    <div>
      <Reveal>
        <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-end">
          <div>
            <p className="text-eyebrow">Teacher Insights</p>
            <h2 className="text-heading mt-2 text-3xl font-bold sm:text-4xl">
              See where the class needs you most.
            </h2>
            <p className="text-body mt-2">{teacherDemoData.subject} · {teacherDemoData.school}</p>
          </div>
          <Badge variant="brand"><Users className="h-3.5 w-3.5" />Ms. Wanjiku</Badge>
        </div>
      </Reveal>

      {/* Stat cards */}
      <div className="mt-7 grid grid-cols-2 gap-4 xl:grid-cols-4">
        {teacherDemoData.stats.map((stat, index) => (
          <Reveal key={stat.label} delay={index * 70}>
            <div className="surface p-4 sm:p-5">
              <p className="text-xs font-semibold text-ink-500">{stat.label}</p>
              <p className="mt-2 font-display text-2xl font-extrabold text-ink-900 sm:text-3xl">{stat.value}</p>
            </div>
          </Reveal>
        ))}
      </div>

      {/* Class mastery + needs attention */}
      <div className="mt-5 grid gap-5 xl:grid-cols-[minmax(0,1fr)_20rem]">
        <Reveal>
          <div className="surface p-5 sm:p-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-ink-400">Class mastery</p>
                <h3 className="text-heading mt-1 text-xl font-bold">Grade 8 Mathematics</h3>
              </div>
              <Badge variant="neutral">38 students</Badge>
            </div>
            <div className="mt-6 space-y-5">
              {teacherDemoData.mastery.map((item) => (
                <div key={item.label}>
                  <div className="mb-2 flex items-center justify-between text-sm">
                    <span className={item.value < 50 ? 'font-bold text-orange-700' : 'font-semibold text-ink-700'}>
                      {item.label}
                    </span>
                    <span className="font-bold text-ink-800">{item.value}%</span>
                  </div>
                  <ProgressBar
                    value={item.value}
                    size="md"
                    className={item.value < 50 ? '[&>div>div]:bg-orange-500' : ''}
                  />
                </div>
              ))}
            </div>
          </div>
        </Reveal>

        <Reveal delay={100}>
          <div className="rounded-2xl border border-orange-200 bg-orange-50 p-5">
            <div className="flex items-start gap-3">
              <AlertTriangle className="mt-0.5 h-5 w-5 shrink-0 text-orange-600" />
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-orange-700">Needs attention</p>
                <h3 className="mt-2 font-display text-lg font-bold text-orange-900">Algebraic Word Problems</h3>
                <p className="mt-2 text-sm text-orange-800">18 students are below the current mastery threshold.</p>
              </div>
            </div>
            <button
              onClick={toggleTeacherStudents}
              className="mt-5 inline-flex items-center gap-2 text-sm font-bold text-orange-800 hover:text-orange-950"
            >
              {teacherStudentsVisible ? 'Hide students' : 'View students'}
              <ArrowRight className="h-4 w-4" />
            </button>
          </div>
        </Reveal>
      </div>

      {/* Student table */}
      {teacherStudentsVisible && (
        <Reveal className="mt-5">
          <div className="surface overflow-hidden">
            <div className="border-b border-ink-200 p-5">
              <h3 className="font-display font-bold text-ink-900">Grade 8 students</h3>
              <p className="mt-1 text-xs text-ink-500">
                Synthetic demo data · individual progress is shown to support timely help.
              </p>
            </div>
            <div className="overflow-x-auto">
              <table className="w-full min-w-[680px] text-left text-sm">
                <thead className="bg-ink-50 text-xs font-bold uppercase tracking-wider text-ink-500">
                  <tr>
                    <th className="px-5 py-3">Student</th>
                    <th className="px-5 py-3">Mastery</th>
                    <th className="px-5 py-3">Practice sessions</th>
                    <th className="px-5 py-3">Last active</th>
                    <th className="px-5 py-3">Status</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-ink-100">
                  {teacherDemoData.students.map((student) => (
                    <tr key={student.name} className="text-ink-700">
                      <td className="px-5 py-3 font-semibold text-ink-900">{student.name}</td>
                      <td className="px-5 py-3">{student.mastery}%</td>
                      <td className="px-5 py-3">{student.sessions}</td>
                      <td className="px-5 py-3">{student.active}</td>
                      <td className="px-5 py-3">
                        <Badge variant={statusVariant[student.status] ?? 'neutral'}>
                          {student.status}
                        </Badge>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </Reveal>
      )}

      {/* Insight + engagement */}
      <div className="mt-5 grid gap-5 lg:grid-cols-2">
        <Reveal>
          <div className="surface h-full p-5 sm:p-6">
            <div className="flex items-center gap-2">
              <FileText className="h-4 w-4 text-brand-600" />
              <p className="text-xs font-bold uppercase tracking-wider text-brand-600">Teacher insight</p>
            </div>
            <h3 className="text-heading mt-3 text-xl font-bold">Suggested class focus</h3>
            <p className="text-body mt-2 text-sm">
              Consider revisiting algebraic word problems. This is currently the weakest shared topic across the class.
            </p>
            <p className="mt-4 text-xs font-semibold text-ink-400">Based on 426 recent practice attempts.</p>
            <button
              onClick={() => setAssignOpen(true)}
              className="mt-5 rounded-xl bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-700"
            >
              Assign practice
            </button>
            {assignmentState === 'assigned' && (
              <p className="mt-3 flex items-center gap-2 text-xs font-bold text-emerald-700">
                <CheckCircle2 className="h-4 w-4" />
                Practice assigned to Grade 8A.
              </p>
            )}
          </div>
        </Reveal>

        <Reveal delay={100}>
          <div className="surface p-5 sm:p-6">
            <p className="text-xs font-bold uppercase tracking-wider text-ink-400">Weekly engagement</p>
            <div className="mt-5 flex h-32 items-end gap-3">
              {[68, 82, 58, 76, 90, 72, 64].map((value, index) => (
                <div key={index} className="flex flex-1 flex-col items-center gap-2">
                  <div className="flex h-24 w-full items-end">
                    <div
                      className="w-full rounded-t-md bg-brand-500"
                      style={{ height: `${value}%` }}
                    />
                  </div>
                  <span className="text-[10px] font-semibold text-ink-400">
                    {['M', 'T', 'W', 'T', 'F', 'S', 'S'][index]}
                  </span>
                </div>
              ))}
            </div>
            <p className="mt-3 text-xs text-ink-500">34 of 38 students active this week.</p>
          </div>
        </Reveal>
      </div>

      {/* Assign modal */}
      {assignOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink-950/30 p-4">
          <div className="w-full max-w-sm animate-scale-in rounded-2xl bg-white p-6 shadow-lift">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs font-bold uppercase tracking-wider text-brand-600">Assign practice</p>
                <h3 className="mt-2 font-display text-xl font-bold text-ink-900">Algebraic Word Problems</h3>
              </div>
              <button
                onClick={() => setAssignOpen(false)}
                className="rounded-lg p-2 text-ink-400 hover:bg-ink-100"
                aria-label="Close assignment dialog"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
            <div className="mt-5 space-y-3 rounded-xl bg-ink-50 p-4 text-sm">
              <p><span className="text-ink-500">To:</span> <strong>Grade 8A</strong></p>
              <p><span className="text-ink-500">Recommended:</span> <strong>15 minutes</strong></p>
            </div>
            <button
              onClick={() => { assignPractice(); setAssignOpen(false); }}
              className="mt-5 w-full rounded-xl bg-brand-600 px-4 py-2.5 text-sm font-semibold text-white hover:bg-brand-700"
            >
              Assign
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
