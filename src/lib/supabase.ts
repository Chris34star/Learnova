import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;
export const isSupabaseConfigured = Boolean(url && anonKey);

// A harmless local URL keeps the public site renderable before environment setup.
// No privileged key is ever accepted by the browser application.
export const supabase = createClient(url ?? 'http://127.0.0.1:54321', anonKey ?? 'not-configured', {
  auth: { persistSession: true, autoRefreshToken: true, detectSessionInUrl: true },
});
