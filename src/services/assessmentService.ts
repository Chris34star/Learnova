import {supabase} from '@/lib/supabase';

export type MasteryLevel='still_learning'|'needs_practice'|'developing'|'on_track'|'strong';
export interface SkillMastery{id:string;skill_id:string;mastery_score:number;confidence_score:number;evidence_count:number;recent_correct_count:number;recent_attempt_count:number;mastery_level:MasteryLevel;needs_practice:boolean;last_practiced_at:string|null;skills?:{name:string;course_id:string}}
export interface PracticeRecommendation{id:string;skill_id:string;course_id:string;reason:string;priority:number;skills?:{name:string}}
export interface PracticeQuestion{id:string;course_id:string;question_type:'multiple_choice'|'multiple_select'|'true_false'|'short_answer'|'numeric';question_text:string;difficulty:string;hint:string|null;points:number;options:{id:string;text:string;sort_order:number}[]}
export interface AnswerResult{is_correct:boolean;score_awarded:number;feedback:string;explanation:string;correct_answer:unknown}

async function unwrap<T>(request:PromiseLike<{data:unknown;error:{message:string}|null}>):Promise<T>{const {data,error}=await request;if(error)throw new Error(error.message);if(data===null)throw new Error('No assessment data was returned.');return data as T}

export const masteryLabel=(row:Pick<SkillMastery,'evidence_count'|'mastery_level'>)=>row.evidence_count<3?'Still learning':({needs_practice:'Needs Practice',developing:'Developing',on_track:'On Track',strong:'Strong understanding',still_learning:'Still learning'} as const)[row.mastery_level];
export const confidenceLabel=(score:number)=>score>=75?'High':score>=40?'Medium':'Low';

export const assessmentService={
  mastery:()=>unwrap<SkillMastery[]>(supabase.from('student_skill_mastery').select('*,skills(name,course_id)').order('mastery_score')),
  recommendations:()=>unwrap<PracticeRecommendation[]>(supabase.from('practice_recommendations').select('id,skill_id,course_id,reason,priority,skills(name)').eq('status','active').order('priority',{ascending:false})),
  assignments:()=>unwrap<{id:string;skill_id:string;question_count:number;difficulty_range:string[];due_at:string|null;skills?:{name:string}}[]>(supabase.from('practice_assignments').select('id,skill_id,question_count,difficulty_range,due_at,skills(name)').eq('status','active')),
  questions:(skillId:string,count=5)=>unwrap<PracticeQuestion[]>(supabase.rpc('select_practice_questions',{target_skill:skillId,requested_count:count})),
  answer:(attemptId:string,questionId:string,answer:Record<string,unknown>,hintUsed:boolean,seconds:number)=>unwrap<AnswerResult>(supabase.rpc('submit_question_answer',{attempt:attemptId,question:questionId,answer,used_hint:hintUsed,elapsed:seconds})),
  start:(skillId:string,count=5)=>unwrap<{attempt_id:string;questions:PracticeQuestion[]}>(supabase.rpc('start_practice_attempt',{target_skill:skillId,requested_count:count})),
  complete:(attemptId:string)=>unwrap<{raw_score:number;percentage_score:number}>(supabase.rpc('complete_assessment_attempt',{attempt:attemptId})),
  teacherMastery:(studentId:string)=>unwrap<SkillMastery[]>(supabase.from('student_skill_mastery').select('*,skills(name,course_id)').eq('student_id',studentId).order('mastery_score')),
  teacherRecommendations:(studentId:string)=>unwrap<PracticeRecommendation[]>(supabase.from('practice_recommendations').select('id,skill_id,course_id,reason,priority,skills(name)').eq('student_id',studentId).eq('status','active')),
  assign:(payload:{student_id?:string;class_id?:string;skill_id:string;question_count:number;difficulty_range:string[];due_at?:string})=>unwrap(supabase.rpc('assign_practice',payload)),
};

