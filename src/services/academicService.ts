import { supabase } from '@/lib/supabase';
import type { Grade, SchoolClass, Subject, SchoolSettings } from '@/types';
const unwrap=<T>(data:T|null,error:{message:string}|null):T=>{if(error)throw new Error(error.message);return data as T};
export const academicService={
 async grades(){const {data,error}=await supabase.from('grades').select('*').order('display_order');return unwrap(data,error) as Grade[]},
 async saveGrade(input:Partial<Grade>&Pick<Grade,'school_id'|'name'>){const {data,error}=await supabase.from('grades').upsert(input).select().single();return unwrap(data,error) as Grade},
 async classes(){const {data,error}=await supabase.from('classes').select('*,grades(name),student_profiles(count)').order('name');return unwrap(data,error) as SchoolClass[]},
 async saveClass(input:Partial<SchoolClass>&Pick<SchoolClass,'school_id'|'grade_id'|'name'>){const {data,error}=await supabase.from('classes').upsert(input).select().single();return unwrap(data,error) as SchoolClass},
 async subjects(){const {data,error}=await supabase.from('subjects').select('*').order('name');return unwrap(data,error) as Subject[]},
 async saveSubject(input:Partial<Subject>&Pick<Subject,'name'|'slug'>){const {data,error}=await supabase.from('subjects').upsert(input).select().single();return unwrap(data,error) as Subject},
 async assignSubject(school_id:string,grade_id:string,subject_id:string,assigned:boolean){const query=supabase.from('grade_subjects'); const {error}=assigned?await query.upsert({school_id,grade_id,subject_id},{onConflict:'grade_id,subject_id'}):await query.delete().eq('grade_id',grade_id).eq('subject_id',subject_id);if(error)throw error},
 async settings(){const {data,error}=await supabase.from('school_settings').select('*').maybeSingle();return unwrap(data,error) as SchoolSettings|null},
 async saveSettings(input:Partial<SchoolSettings>&Pick<SchoolSettings,'school_id'>){const {data,error}=await supabase.from('school_settings').upsert(input,{onConflict:'school_id'}).select().single();return unwrap(data,error) as SchoolSettings},
};
