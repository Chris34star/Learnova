export {milestoneProgress,canSubmit} from './projectProgress';
import {supabase} from '@/lib/supabase';

export type ProjectStatus='not_started'|'in_progress'|'submitted'|'needs_revision'|'completed';
export interface SkillsPathway{id:string;title:string;description:string;category:string;difficulty:string;student_pathway_progress?:{progress_percentage:number;current_level:number;status:string}[]}
export interface PathwayItem{id:string;level:number;sort_order:number;is_required:boolean;course_id:string|null;content_node_id:string|null;skill_id:string|null;courses?:{title:string;description:string}|null;content_nodes?:{title:string;content_type:string}|null;skills?:{name:string}|null}
export interface ProjectDefinition{id:string;pathway_id:string|null;course_id:string|null;title:string;description:string;difficulty:string;estimated_minutes:number|null;instructions:string;success_criteria_json:{key?:string;label:string}[];submission_schema_json:Record<string,boolean>;project_milestones?:ProjectMilestone[]}
export interface ProjectMilestone{id:string;title:string;description:string;instructions:string;sort_order:number;required:boolean;estimated_minutes:number|null;related_content_node_id:string|null}
export interface StudentProject{id:string;student_id:string;project_id:string;pathway_id:string|null;title:string;status:ProjectStatus;student_reflection:string|null;teacher_feedback:string|null;submission_json:Record<string,string>;submitted_at:string|null;completed_at:string|null;projects?:ProjectDefinition;student_project_milestones?:StudentMilestone[];student_profiles?:{profiles?:{display_name:string}}}
export interface StudentMilestone{id:string;project_milestone_id:string;status:'not_started'|'in_progress'|'completed';student_notes:string|null;completed_at:string|null;project_milestones?:ProjectMilestone}

async function rows<T>(request:PromiseLike<{data:T|null;error:{message:string}|null}>):Promise<T>{const result=await request;if(result.error)throw new Error(result.error.message);return (result.data??[]) as T}
export const skillsLabService={
 pathways:()=>rows<SkillsPathway[]>(supabase.from('learning_pathways').select('id,title,description,category,difficulty,student_pathway_progress(progress_percentage,current_level,status)').eq('category','skill').eq('status','published').order('title')),
 pathwayItems:(id:string)=>rows<PathwayItem[]>(supabase.from('pathway_items').select('*,courses(title,description),content_nodes(title,content_type),skills(name)').eq('pathway_id',id).order('level').order('sort_order')),
 projects:()=>rows<ProjectDefinition[]>(supabase.from('projects').select('*,project_milestones(*)').eq('status','published').order('created_at')),
 myProjects:()=>rows<StudentProject[]>(supabase.from('student_projects').select('*,projects(*,project_milestones(*)),student_project_milestones(*,project_milestones(*))').not('project_id','is',null).order('updated_at',{ascending:false})),
 project:(id:string)=>rows<StudentProject[]>(supabase.from('student_projects').select('*,projects(*,project_milestones(*)),student_project_milestones(*,project_milestones(*)),project_reviews(*)').eq('id',id).limit(1)).then(x=>{if(!x[0])throw new Error('Project not found or you do not have access.');return x[0]}),
 start:(id:string)=>rows<StudentProject>(supabase.rpc('start_student_project',{requested_project:id})),
 saveMilestone:(projectId:string,milestoneId:string,status:'in_progress'|'completed',notes:string)=>rows<number>(supabase.rpc('save_project_milestone',{requested_student_project:projectId,requested_milestone:milestoneId,requested_status:status,requested_notes:notes})),
 submit:(id:string,submission:Record<string,string>,reflection:string)=>rows<StudentProject>(supabase.rpc('submit_student_project',{requested_student_project:id,requested_submission:submission,requested_reflection:reflection})),
 reviewQueue:()=>rows<StudentProject[]>(supabase.from('student_projects').select('*,projects(*,project_milestones(*)),student_project_milestones(*,project_milestones(*)),student_profiles(profiles(display_name))').not('project_id','is',null).order('updated_at',{ascending:false})),
 review:(id:string,status:'approved'|'revision_requested',feedback:string,criteria:Record<string,boolean>)=>rows<StudentProject>(supabase.rpc('review_student_project',{requested_student_project:id,requested_status:status,requested_feedback:feedback,requested_criteria:criteria})),
 assignments:()=>rows<{id:string;assignment_type:string;target_id:string;due_at:string|null;instructions:string|null;teacher_profiles?:{profiles?:{display_name:string}}}[]>(supabase.from('learning_assignments').select('*,teacher_profiles(profiles(display_name))').eq('status','active').order('due_at')),
};
