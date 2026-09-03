import {supabase} from '@/lib/supabase';

export type ProgressStatus='not_started'|'in_progress'|'completed';
export interface LearningCourse{id:string;title:string;description:string;content_family:'academic'|'skills';difficulty:string|null;learning_objectives:string[];subject_id:string|null}
export interface LearningNode{id:string;course_id:string;parent_id:string|null;sort_order:number;content_type:string;title:string;body:string;structured_content:Record<string,unknown>;learning_objectives:string[];metadata:Record<string,unknown>;status:string}
export interface NodeProgress{content_node_id:string;course_id:string;status:ProgressStatus;last_position_json:{sectionId?:string}|null;time_spent_seconds:number;started_at:string|null;completed_at:string|null;updated_at:string}
export interface CourseProgressSummary{course_id:string;required_count:number;completed_count:number;progress_percent:number;current_content_node_id:string|null}
export const REQUIRED_TYPES=new Set(['lesson','activity','practice','project','challenge','milestone']);

async function data<T>(request:PromiseLike<{data:T|null;error:{message:string}|null}>):Promise<T>{const result=await request;if(result.error)throw new Error(result.error.message);if(result.data===null)throw new Error('No learning data was returned.');return result.data}
export function courseProgress(nodes:LearningNode[],progress:NodeProgress[]){const required=nodes.filter(n=>REQUIRED_TYPES.has(n.content_type));const done=required.filter(n=>progress.some(p=>p.content_node_id===n.id&&p.status==='completed')).length;return {done,total:required.length,percent:required.length?Math.round(done/required.length*100):0,completed:required.length>0&&done===required.length}}
export function orderedLessons(nodes:LearningNode[]){return nodes.filter(n=>REQUIRED_TYPES.has(n.content_type)).sort((a,b)=>a.sort_order-b.sort_order||a.title.localeCompare(b.title))}

export const learningService={
 courses:()=>data<LearningCourse[]>(supabase.rpc('student_available_courses')),
 nodes:(courseId:string)=>data<LearningNode[]>(supabase.rpc('student_course_nodes',{requested_course_id:courseId})),
 progress:()=>data<NodeProgress[]>(supabase.from('student_content_progress').select('*').order('updated_at',{ascending:false})),
 summaries:()=>data<CourseProgressSummary[]>(supabase.rpc('student_course_progress')),
 progressForCourse:(courseId:string)=>data<NodeProgress[]>(supabase.from('student_content_progress').select('*').eq('course_id',courseId).order('updated_at',{ascending:false})),
 save:(courseId:string,nodeId:string,status:ProgressStatus,sectionId?:string,seconds=0,event?:string)=>data<NodeProgress>(supabase.rpc('save_learning_progress',{requested_course_id:courseId,requested_node_id:nodeId,requested_status:status,requested_position:sectionId?{sectionId}:null,elapsed_seconds:seconds,requested_event:event??null})),
 recentEvents:()=>data<{id:string;course_id:string|null;content_node_id:string|null;event_type:string;created_at:string}[]>(supabase.from('learning_events').select('id,course_id,content_node_id,event_type,created_at').order('created_at',{ascending:false}).limit(12)),
 sessions:()=>data<{duration_seconds:number|null;started_at:string}[]>(supabase.from('learning_sessions').select('duration_seconds,started_at').order('started_at',{ascending:false})),
 relationships:()=>data<{from_course_id:string|null;to_course_id:string|null;relationship:string}[]>(supabase.from('content_relationships').select('from_course_id,to_course_id,relationship').in('relationship',['prerequisite','next_level','recommended_after'])),
 studentProjects:()=>data<{id:string;course_id:string;title:string;status:ProgressStatus}[]>(supabase.from('student_projects').select('id,course_id,title,status')),
 teacherStudentProgress:(studentId:string)=>data<NodeProgress[]>(supabase.from('student_content_progress').select('*').eq('student_id',studentId).order('updated_at',{ascending:false})),
 adminMetrics:async()=>{const [events,sessions]=await Promise.all([data<{event_type:string;student_id:string;created_at:string}[]>(supabase.from('learning_events').select('event_type,student_id,created_at').gte('created_at',new Date(Date.now()-7*86400000).toISOString())),data<{id:string}[]>(supabase.from('learning_sessions').select('id').gte('started_at',new Date(Date.now()-7*86400000).toISOString()))]);return {activeLearners:new Set(events.map(e=>e.student_id)).size,lessonsCompleted:events.filter(e=>e.event_type==='lesson_completed').length,courseStarts:events.filter(e=>e.event_type==='course_started').length,courseCompletions:events.filter(e=>e.event_type==='course_completed').length,sessions:sessions.length}},
};
