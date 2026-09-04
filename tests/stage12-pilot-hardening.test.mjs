import assert from 'node:assert/strict';
import {readFileSync,readdirSync} from 'node:fs';
import {join} from 'node:path';

const migration=readFileSync('supabase/migrations/202609040005_stage12_pilot_hardening.sql','utf8');
const identityMigration=readFileSync('supabase/migrations/202609040006_stage12_identity_integrity.sql','utf8');
const edge=readFileSync('supabase/functions/nuru-tutor/index.ts','utf8');
const provider=readFileSync('supabase/functions/nuru-tutor/provider.ts','utf8');
const assessment=readFileSync('supabase/migrations/202609030005_stage7_assessment_mastery.sql','utf8');
const content=readFileSync('supabase/migrations/202609030002_stage4_governed_content.sql','utf8');
const allSource=readdirSync('src',{recursive:true}).filter(file=>/\.(ts|tsx|js|jsx)$/.test(file)).map(file=>readFileSync(join('src',file),'utf8')).join('\n');

// P0 governance regression: teacher checks bind scope, tenant, author, and non-published states.
for(const token of ["school_id=current_school_id()","current_profile_role()='teacher'","created_by=(select id from profiles where user_id=auth.uid())","status in('draft','in_review')"]){
 assert.ok(migration.includes(token),`teacher governance must include ${token}`);
}
assert.match(migration,/drop policy if exists governed_question_write/);
assert.match(migration,/questions_teacher_update[\s\S]*approved_at is null[\s\S]*questions_admin_update/);
assert.match(migration,/assessments_teacher_update[\s\S]*assessments_admin_update/);
assert.match(migration,/drop policy if exists projects_student_write/);
assert.match(migration,/milestones_read[\s\S]*owns_student\(p\.student_id\)[\s\S]*teacher_can_view_student\(p\.student_id\)/);
assert.match(migration,/interventions_teacher_update[\s\S]*teacher_id=.*auth\.uid\(\)[\s\S]*teacher_can_view_student\(student_id\)/);
assert.match(content,/current_profile_role\(\)='student' and status='published' and approved_at is not null/);
assert.match(identityMigration,/protect_profile_authority[\s\S]*new\.user_id, new\.school_id, new\.role[\s\S]*not public\.is_platform_admin\(\)/,'browser-issued updates cannot rewrite identity authority');
assert.match(identityMigration,/revoke execute on function public\.protect_profile_authority\(\) from public, anon, authenticated/);

// Assessment delivery exposes a projection without answer fields; grading remains a caller-owned server RPC.
const projection=assessment.match(/create view public\.student_question_bank[\s\S]*?from questions q where[^;]+;/)?.[0]??'';
assert.ok(projection,'student question projection must exist');
assert.doesNotMatch(projection,/answer_data_json|is_correct|explanation/);
assert.match(assessment,/if not found or not owns_student\(aa\.student_id\)/);
assert.match(assessment,/unique\(assessment_attempt_id,question_id,attempt_number\)/);

// Sensitive RPCs must not retain PostgreSQL's default anonymous/public execution privilege.
for(const fn of ['submit_question_answer','accept_content_proposal','authorize_nuru_generation','start_student_project','teacher_class_intelligence','school_intelligence']){
 assert.match(migration,new RegExp(`revoke execute on function[\\s\\S]{0,700}public\\.${fn}\\(`),`${fn} must be revoked from public/anon`);
}

// Nuru authenticates JWTs, derives trusted context via RPC, restricts origins, times out, and returns generic failures.
assert.match(edge,/client\.auth\.getUser\(\)/);
assert.match(edge,/ALLOWED_ORIGINS/);
assert.doesNotMatch(edge,/Access-Control-Allow-Origin['"]?\s*:\s*['"]\*/);
assert.match(edge,/origin&&!allowedOrigins\.has\(origin\)[\s\S]*nuru_origin_denied[\s\S]*403/,'disallowed POST origins must be rejected before consuming provider credit');
assert.match(edge,/nuru_build_context/);
assert.match(edge,/mode==='assessment'/);
assert.match(edge,/requests_per_ten_minutes/);
assert.match(edge,/x-request-id/);
assert.match(edge,/Nuru could not respond right now\. Your lesson is still available\./);
assert.match(provider,/AbortController/);
assert.match(provider,/15000/);
assert.match(provider,/Provider response was malformed/);

// Privileged secrets are server-only and absent from the browser source.
assert.doesNotMatch(allSource,/SUPABASE_SERVICE_ROLE_KEY|OPENAI_API_KEY|sk-[A-Za-z0-9_-]{16,}/);

console.log('Stage 12 pilot hardening security contracts PASS');
