import { supabase } from '@/lib/supabase';
import type { StudentProfile, TeacherProfile } from '@/types';
export const peopleService={
 async students(){const {data,error}=await supabase.from('student_profiles').select('*,profiles(first_name,last_name,display_name),grades(name),classes(name)').order('created_at',{ascending:false});if(error)throw error;return data as StudentProfile[]},
 async updateStudent(id:string,values:Partial<StudentProfile>){const {error}=await supabase.from('student_profiles').update(values).eq('id',id);if(error)throw error},
 async teachers(){const {data,error}=await supabase.from('teacher_profiles').select('*,profiles(display_name,status),teacher_classes(class_id,classes(name))').order('created_at',{ascending:false});if(error)throw error;return data as TeacherProfile[]},
 async assignClass(school_id:string,teacher_id:string,class_id:string){const {error}=await supabase.from('teacher_classes').upsert({school_id,teacher_id,class_id},{onConflict:'teacher_id,class_id'});if(error)throw error},
};
