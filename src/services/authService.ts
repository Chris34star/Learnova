import { supabase } from '@/lib/supabase';
import type { Profile, School } from '@/types';

export const authService = {
  signIn: (email:string,password:string) => supabase.auth.signInWithPassword({email,password}),
  signOut: () => supabase.auth.signOut(),
  resetPassword: (email:string) => supabase.auth.resetPasswordForEmail(email,{redirectTo:`${window.location.origin}/reset-password`}),
  updatePassword: (password:string) => supabase.auth.updateUser({password}),
  async profile(userId:string):Promise<{profile:Profile|null;school:School|null}> {
    const {data,error}=await supabase.from('profiles').select('*').eq('user_id',userId).maybeSingle();
    if(error) throw error;
    let school:School|null=null;
    if(data?.school_id){ const result=await supabase.from('schools').select('*').eq('id',data.school_id).single(); if(result.error) throw result.error; school=result.data as School; }
    return {profile:data as Profile|null,school};
  }
};
