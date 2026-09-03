import { supabase } from '@/lib/supabase';
import type { School } from '@/types';
export const schoolService={
 async list(){const {data,error}=await supabase.from('schools').select('*').order('created_at',{ascending:false});if(error)throw error;return data as School[]},
 async create(input:Pick<School,'name'|'slug'|'country'> & Partial<School>){const {data,error}=await supabase.from('schools').insert({...input,status:'trial'}).select().single();if(error)throw error;await supabase.from('school_settings').insert({school_id:data.id});return data as School},
 async update(id:string,input:Partial<School>){const {data,error}=await supabase.from('schools').update(input).eq('id',id).select().single();if(error)throw error;return data as School},
};
