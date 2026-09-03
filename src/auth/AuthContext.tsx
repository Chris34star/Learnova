import { createContext,useCallback,useContext,useEffect,useState,type ReactNode } from 'react';
import type { User } from '@supabase/supabase-js';
import { supabase,isSupabaseConfigured } from '@/lib/supabase';
import { authService } from '@/services/authService';
import type { Profile,School,UserRole } from '@/types';

interface AuthValue {user:User|null;profile:Profile|null;school:School|null;role:UserRole|null;loading:boolean;configured:boolean;profileError:string|null;signIn:(e:string,p:string)=>Promise<void>;signOut:()=>Promise<void>;refreshProfile:()=>Promise<void>}
const AuthContext=createContext<AuthValue|null>(null);
export function AuthProvider({children}:{children:ReactNode}){
 const [user,setUser]=useState<User|null>(null),[profile,setProfile]=useState<Profile|null>(null),[school,setSchool]=useState<School|null>(null),[loading,setLoading]=useState(true),[profileError,setProfileError]=useState<string|null>(null);
 const load=useCallback(async(next:User|null)=>{setUser(next);setProfileError(null);if(!next){setProfile(null);setSchool(null);setLoading(false);return}try{const result=await authService.profile(next.id);setProfile(result.profile);setSchool(result.school);if(!result.profile)setProfileError('Your account is authenticated but has not been provisioned. Contact a Learnova administrator.')}catch(e){setProfileError(e instanceof Error?e.message:'Could not load your account.')}finally{setLoading(false)}},[]);
 useEffect(()=>{if(!isSupabaseConfigured){setLoading(false);return}supabase.auth.getSession().then(({data})=>load(data.session?.user??null));const {data}=supabase.auth.onAuthStateChange((_event,session)=>{void load(session?.user??null)});return()=>data.subscription.unsubscribe()},[load]);
 const signIn=async(e:string,p:string)=>{const {data,error}=await authService.signIn(e,p);if(error)throw error;await load(data.user)};
 return <AuthContext.Provider value={{user,profile,school,role:profile?.role??null,loading,configured:isSupabaseConfigured,profileError,signIn,signOut:async()=>{await authService.signOut()},refreshProfile:async()=>load(user)}}>{children}</AuthContext.Provider>
}
export function useAuth(){const value=useContext(AuthContext);if(!value)throw new Error('useAuth must be used inside AuthProvider');return value}
