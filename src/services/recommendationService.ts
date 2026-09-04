import {supabase} from '@/lib/supabase';
import type {RankedRecommendation} from './recommendationEngine';
export type Interest={id:string;interest_key:string;interest_label:string;interest_category:string;interest_level:'curious'|'interested'|'very_interested'};
const throwIf=<T>(r:{data:T;error:unknown})=>{if(r.error)throw r.error;return r.data};
export const recommendationService={
 async recommendations(){return throwIf(await supabase.rpc('generate_student_recommendations')) as RankedRecommendation[]},
 async interests(){return throwIf(await supabase.from('student_interests').select('*').order('created_at')) as Interest[]},
 async saveInterest(value:Omit<Interest,'id'>){return throwIf(await supabase.rpc('set_student_interest',{requested_key:value.interest_key,requested_label:value.interest_label,requested_category:value.interest_category,requested_level:value.interest_level}))},
 async removeInterest(id:string){return throwIf(await supabase.from('student_interests').delete().eq('id',id).select().single())},
 async feedback(targetId:string,type:'interested'|'not_interested'|'maybe_later'|'started'){return throwIf(await supabase.rpc('record_recommendation_feedback',{requested_target:targetId,requested_feedback:type}))},
};
