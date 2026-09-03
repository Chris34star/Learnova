import { supabase } from '@/lib/supabase';

export type ContentStatus='draft'|'in_review'|'approved'|'published'|'rejected'|'archived';
export interface ContentNodeDraft {course_id:string;parent_id?:string;content_type:string;title:string;body?:string;structured_content?:Record<string,unknown>;learning_objectives?:string[];metadata?:Record<string,unknown>;scope:'global'|'school';school_id?:string;source_content_id?:string;is_override?:boolean;created_by:string}

async function requireData<T>(request:PromiseLike<{data:T|null;error:{message:string}|null}>):Promise<T>{const {data,error}=await request;if(error)throw new Error(error.message);if(data===null)throw new Error('The content operation returned no data.');return data}

export const contentService={
 listGlobalCourses:()=>requireData(supabase.from('courses').select('*').eq('scope','global').order('updated_at',{ascending:false})),
 listSchoolCourses:(schoolId:string)=>requireData(supabase.from('courses').select('*').eq('school_id',schoolId).order('updated_at',{ascending:false})),
 adoptCourse:(schoolId:string,courseId:string,profileId:string)=>requireData(supabase.from('school_course_adoptions').upsert({school_id:schoolId,course_id:courseId,adopted_by:profileId,active:true},{onConflict:'school_id,course_id'}).select().single()),
 effectiveNodes:(schoolId:string,courseId:string)=>requireData(supabase.rpc('effective_course_nodes',{adoption_school_id:schoolId,adopted_course_id:courseId})),
 createDraft:(draft:ContentNodeDraft)=>requireData(supabase.from('content_nodes').insert({...draft,status:'draft'}).select().single()),
 createOverride:(source:ContentNodeDraft&{id:string},schoolId:string,profileId:string)=>contentService.createDraft({...source,scope:'school',school_id:schoolId,source_content_id:source.id,course_id:source.course_id,is_override:true,created_by:profileId}),
 revertOverride:(overrideId:string)=>requireData(supabase.from('content_nodes').update({status:'archived'}).eq('id',overrideId).select().single()),
 submitForReview:async(nodeId:string,schoolId:string|undefined,profileId:string,version:number)=>{
  await requireData(supabase.from('content_nodes').update({status:'in_review'}).eq('id',nodeId).eq('status','draft').select().single());
  return requireData(supabase.from('content_reviews').insert({content_node_id:nodeId,version,school_id:schoolId,submitted_by:profileId,decision:'submitted'}).select().single());
 },
 proposeToGlobal:(schoolId:string,nodeId:string,profileId:string,note?:string)=>requireData(supabase.from('content_proposals').insert({school_id:schoolId,source_content_id:nodeId,proposed_by:profileId,note}).select().single()),
 acceptProposal:(proposalId:string)=>requireData(supabase.rpc('accept_content_proposal',{proposal_id:proposalId})),
 versions:(nodeId:string)=>requireData(supabase.from('content_versions').select('*,author:profiles!author_id(display_name)').eq('content_node_id',nodeId).order('version',{ascending:false})),
};
