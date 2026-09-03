import {supabase} from '@/lib/supabase';
import type {ContentContext,ContentSuggestion,NuruScope} from './types';

const dataOrThrow=async<T>(request:PromiseLike<{data:T|null;error:{message:string}|null}>):Promise<T>=>{const {data,error}=await request;if(error)throw new Error(error.message);if(data===null)throw new Error('Nuru operation returned no data.');return data};

/** Persistence boundary only; provider calls belong on a trusted server when a real vendor is enabled. */
export const nuruService={
 listSuggestions:(scope:NuruScope,schoolId?:string)=>{let query=supabase.from('content_suggestions').select('*').eq('scope',scope).order('created_at',{ascending:false});if(schoolId)query=query.eq('school_id',schoolId);return dataOrThrow(query)},
 authorizeGeneration:(scope:NuruScope,schoolId:string|undefined,requestType:string,context:ContentContext,summary:string)=>dataOrThrow<string>(supabase.rpc('authorize_nuru_generation',{request_scope:scope,request_school_id:schoolId??null,request_type:requestType,controlled_context:context,summary,provider_name:'mock'})),
 markSuggestion:(id:string,status:ContentSuggestion['status'],reviewedBy:string)=>dataOrThrow(supabase.from('content_suggestions').update({status,reviewed_by:reviewedBy,reviewed_at:new Date().toISOString()}).eq('id',id).select().single()),
 dismiss:(suggestionId:string,createdBy:string,reason:string,note?:string)=>dataOrThrow(supabase.from('content_suggestion_feedback').insert({suggestion_id:suggestionId,created_by:createdBy,reason,note}).select().single()),
 saveGeneratedItem:(generationRequestId:string,contentId:string,itemType:string)=>dataOrThrow(supabase.from('ai_generated_items').insert({generation_request_id:generationRequestId,content_id:contentId,item_type:itemType,review_status:'draft'}).select().single()),
};
