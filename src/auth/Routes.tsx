import { Navigate,Outlet } from 'react-router-dom';
import { ShieldAlert } from 'lucide-react';
import { useAuth } from './AuthContext';
import type { UserRole } from '@/types';
export const roleHome:Record<UserRole,string>={platform_admin:'/platform',school_admin:'/school',teacher:'/teacher',student:'/app'};
function Center({children}:{children:React.ReactNode}){return <main className="min-h-screen grid place-items-center bg-ink-50 p-6"><div className="surface max-w-lg p-8 text-center">{children}</div></main>}
export function ProtectedRoute(){const {user,loading,profileError}=useAuth();if(loading)return <Center><p>Loading your workspace…</p></Center>;if(!user)return <Navigate to="/login" replace/>;if(profileError)return <Center><ShieldAlert className="mx-auto mb-4 text-accent-600"/><h1 className="text-heading text-xl">Account setup required</h1><p className="mt-2 text-body">{profileError}</p></Center>;return <Outlet/>}
export function RoleRoute({allow}:{allow:UserRole}){const {role}=useAuth();if(role!==allow)return <Center><ShieldAlert className="mx-auto mb-4 text-brand-700"/><h1 className="text-heading text-xl">You don't have access to this area.</h1><p className="mt-2 text-body">Ask your administrator if you believe this is a mistake.</p></Center>;return <Outlet/>}
export function AuthLanding(){const {role}=useAuth();return role?<Navigate to={roleHome[role]} replace/>:<Navigate to="/login" replace/>}
