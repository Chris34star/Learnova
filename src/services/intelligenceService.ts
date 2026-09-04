import {supabase} from '@/lib/supabase';

export interface ClassGap {skill_id:string;skill_name:string;affected:number;improving:number}
export interface SupportInsight {student_id:string;display_name:string;skill_id:string;skill_name:string;mastery:number;confidence:number;evidence_count:number;reason_code:string}
export interface ClassIntelligence {class:{id:string;name:string;grade:string};studentCount:number;recentActivity:number;practiceAttempts:number;completionPercent:number;understandingPercent:number;masteryBands:{needsPractice:number;developing:number;onTrack:number;strong:number};gaps:ClassGap[];support:SupportInsight[];lowEvidenceCount:number}
export interface PlanItem {kind:'assignment'|'practice'|'lesson'|'recommendation'|'project';target_id:string;due_at:string|null;minutes:number;priority:number;reason:string}
export interface DailyPlan {recommendedMinutes:number;studyWindow:string|null;examMode:{title:string;description:string;endsOn:string}|null;items:PlanItem[]}
export interface SchoolIntelligence {activeStudents:number;activeLearners7d:number;lessonsCompleted7d:number;averageCompletion:number;averageUnderstanding:number;practiceAttempts7d:number;projectsActive:number;projectsCompleted:number;pathwaysActive:number;interventionsActive:number}
async function rpc<T>(name:string,args:Record<string,unknown>={}){const {data,error}=await supabase.rpc(name,args);if(error)throw new Error(error.message);return data as T}
export const supportReason=(code:string)=>({low_mastery_sufficient_evidence:'Mastery is currently developing across several attempts with sufficient confidence.',repeated_recent_incorrect:'Several recent responses suggest another round of practice may help.',recent_improvement:'Recent evidence shows consistent improvement.'}[code]??'Recent learning evidence suggests teacher review may be useful.');
export const intelligenceService={
 classInsights:(classId:string)=>rpc<ClassIntelligence>('teacher_class_intelligence',{requested_class:classId}),
 dailyPlan:()=>rpc<DailyPlan>('student_daily_plan'),
 school:()=>rpc<SchoolIntelligence>('school_intelligence'),
 configureGrade:(gradeId:string,minutes:number,start:string|null,end:string|null)=>rpc('configure_grade_learning',{requested_grade:gradeId,requested_minutes:minutes,requested_start:start,requested_end:end}),
 saveExamMode:(input:{id?:string;classId?:string;title:string;description:string;start:string;end:string;courseIds?:string[];enabled:boolean})=>rpc('save_exam_mode',{requested_id:input.id??null,requested_class:input.classId??null,requested_title:input.title,requested_description:input.description,requested_start:input.start,requested_end:input.end,requested_courses:input.courseIds??[],requested_enabled:input.enabled}),
 intervene:(input:{studentId?:string;classId?:string;skillId?:string;type:string;reason:string;note?:string;reviewOn?:string})=>rpc('record_learning_intervention',{requested_student:input.studentId??null,requested_class:input.classId??null,requested_skill:input.skillId??null,requested_type:input.type,requested_reason:input.reason,requested_note:input.note??null,requested_review:input.reviewOn??null}),
 examModes:async()=>{const {data,error}=await supabase.from('exam_modes').select('*').order('starts_on',{ascending:false});if(error)throw new Error(error.message);return data},
 gradeSettings:async()=>{const {data,error}=await supabase.from('grade_learning_settings').select('*,grades(name)').order('updated_at',{ascending:false});if(error)throw new Error(error.message);return data},
};
