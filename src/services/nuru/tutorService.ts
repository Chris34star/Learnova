import {supabase} from '@/lib/supabase';
import type {NuruRequest,NuruResponse} from './tutorTypes';
async function invoke<T>(name:string,body:Record<string,unknown>):Promise<T>{const {data,error}=await supabase.functions.invoke(name,{body});if(error)throw new Error(error.message);return data as T}
export const tutorService={ask:(request:NuruRequest)=>invoke<NuruResponse>('nuru-tutor',{...request}),feedback:async(interactionId:string,rating:'helpful'|'not_helpful',reason?:string)=>{const {error}=await supabase.rpc('save_nuru_feedback',{requested_interaction:interactionId,requested_rating:rating,requested_reason:reason??null});if(error)throw new Error(error.message)}};
