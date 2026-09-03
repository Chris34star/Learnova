import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const sql=readFileSync(new URL('../supabase/migrations/202609030002_stage4_governed_content.sql',import.meta.url),'utf8');
const has=(pattern,message)=>assert.match(sql,pattern,message);

has(/school_course_adoptions/, 'global adoption must be stored by reference');
has(/source_content_id uuid references public\.content_nodes/, 'overrides must retain their global source');
has(/one_active_override/, 'only one active override may replace a source node');
has(/effective_course_nodes/, 'effective inherited trees need a database resolver');
has(/status='published' and n\.approved_at is not null/, 'student content must be published and human-approved');
has(/nodes_teacher_own_draft/, 'teachers need an own-draft-only update policy');
has(/current_profile_role\(\)='school_admin'/, 'school administration must be explicit in RLS');
has(/content_versions/, 'immutable content history must exist');
has(/content_nodes_version_update/, 'edits must automatically produce revisions');
has(/content_nodes_audit/, 'content changes must automatically create audit events');
has(/content_proposals/, 'school content promotion must use proposals');
has(/origin_school_course_id/, 'global derivatives must preserve provenance');
has(/accept_content_proposal/, 'proposal acceptance must derive a separate global draft');
has(/origin_school_content_id/, 'derived global nodes must retain school-content provenance');

console.log('Stage 4 schema contract verified.');
