import {createClient} from 'https://esm.sh/@supabase/supabase-js@2';
import {OpenAITutorProvider,type StructuredTutorResponse} from './provider.ts';

const allowedInteractions=new Set(['explain','simplify','example','hint','mistake','practice','recommendation','compare','question']);
const defaultDevelopmentOrigins=['http://localhost:5173','http://127.0.0.1:5173'];
const configuredOrigins=(Deno.env.get('ALLOWED_ORIGINS')??'').split(',').map(value=>value.trim()).filter(Boolean);
const allowedOrigins=new Set(configuredOrigins.length>0?configuredOrigins:defaultDevelopmentOrigins);

function corsHeaders(req:Request){
 const origin=req.headers.get('origin');
 return {
  ...(origin&&allowedOrigins.has(origin)?{'Access-Control-Allow-Origin':origin,'Vary':'Origin'}:{}),
  'Access-Control-Allow-Headers':'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods':'POST, OPTIONS',
 };
}

Deno.serve(async(req)=>{
 const requestId=req.headers.get('x-request-id')??crypto.randomUUID();
 const respond=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...corsHeaders(req),'content-type':'application/json','x-request-id':requestId}});
 if(req.method==='OPTIONS')return req.headers.get('origin')&&allowedOrigins.has(req.headers.get('origin')!)?new Response(null,{status:204,headers:corsHeaders(req)}):respond({error:'Origin is not allowed'},403);
 if(req.method!=='POST')return respond({error:'Method not allowed'},405);
 const origin=req.headers.get('origin');
 if(origin&&!allowedOrigins.has(origin)){
  console.warn(JSON.stringify({level:'warn',event:'nuru_origin_denied',requestId,timestamp:new Date().toISOString()}));
  return respond({error:'Origin is not allowed'},403);
 }
 try{
  const auth=req.headers.get('authorization');
  if(!auth)return respond({error:'Authentication required'},401);
  const url=Deno.env.get('SUPABASE_URL'),anonKey=Deno.env.get('SUPABASE_ANON_KEY'),serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY'),providerKey=Deno.env.get('OPENAI_API_KEY');
  if(!url||!anonKey||!serviceKey||!providerKey)throw new Error('Required server configuration is missing');
  const client=createClient(url,anonKey,{global:{headers:{authorization:auth}}});
  const {data:{user},error:userError}=await client.auth.getUser();
  if(userError||!user){console.warn(JSON.stringify({level:'warn',event:'nuru_unauthorized',requestId,timestamp:new Date().toISOString()}));return respond({error:'Authentication required'},401)}
  const admin=createClient(url,serviceKey);
  let body:Record<string,unknown>;
  try{body=await req.json()}catch{return respond({error:'Invalid JSON request'},400)}
  const question=String(body.question??'').trim(),interactionType=String(body.interactionType??'question');
  if(!question||question.length>600||!allowedInteractions.has(interactionType))return respond({error:'Invalid tutor request'},400);
  const contextCall=body.studentProjectId?client.rpc('nuru_build_project_context',{requested_student_project:body.studentProjectId}):client.rpc('nuru_build_context',{requested_course:body.courseId??null,requested_node:body.contentNodeId??null,requested_attempt:body.assessmentAttemptId??null,requested_question:body.questionId??null,requested_recommendation:body.recommendationTargetId??null});
  const [{data:context,error},{data:plan}]=await Promise.all([contextCall,client.rpc('student_daily_plan')]);
  if(error||!context){console.warn(JSON.stringify({level:'warn',event:'nuru_context_denied',requestId,userId:user.id,timestamp:new Date().toISOString()}));return respond({error:'Approved learning context unavailable'},403)}
  if(plan){context.schedule={recommendedMinutes:plan.recommendedMinutes,examMode:plan.examMode,activeItems:(plan.items??[]).slice(0,3).map((x:Record<string,unknown>)=>({kind:x.kind,reason:x.reason}))}}
  const studentId=context.student.id,schoolId=context.school.id,settings=context.settings,since=new Date(Date.now()-600000).toISOString();
  const {count,error:countError}=await admin.from('nuru_interactions').select('id',{count:'exact',head:true}).eq('student_id',studentId).gte('created_at',since);
  if(countError)throw new Error('Usage check failed');
  if((count??0)>=settings.requests_per_ten_minutes)return respond({error:'Rate limit reached'},429);
  let chosen=interactionType,restricted=false;const mode=context.mode as string,assessment=context.assessment;
  if(mode==='assessment'&&['example','practice','mistake'].includes(chosen)){chosen='hint';restricted=true}
  if(mode==='assessment'&&chosen==='hint'&&!assessment?.hintsAllowed)return respond({interactionId:crypto.randomUUID(),type:'clarifying_question',title:'Assessment help is limited',content:'I can clarify the wording, but hints are disabled for this assessment.',followUps:['Clarify the wording'],mode,restricted:true});
  if(mode==='practice'&&!context.currentQuestion?.attempted&&['mistake','example'].includes(chosen)){chosen='hint';restricted=true}
  const requestedLevel=Number(body.hintLevel??1),level=Math.min(Math.max(Number.isFinite(requestedLevel)?requestedLevel:1,1),assessment?.maximumHintLevel??3);
  const provider=new OpenAITutorProvider(providerKey);let result:StructuredTutorResponse;const c=JSON.parse(JSON.stringify(context));
  if(chosen==='simplify')result=await provider.simplifyExplanation(c,question);else if(chosen==='example')result=await provider.giveExample(c,question);else if(chosen==='hint')result=await provider.giveHint(c,question,level);else if(chosen==='mistake')result=await provider.explainMistake(c,question);else if(chosen==='practice')result=await provider.generatePracticeExample(c,question);else if(chosen==='recommendation'||chosen==='compare')result=await provider.explainRecommendation(c,question);else if(chosen==='explain')result=await provider.explainConcept(c,question);else result=await provider.answerLearningQuestion(c,question);
  const validTypes=new Set(['explanation','hint','worked_example','mistake_explanation','concept_connection','practice_prompt','recommendation_explanation','clarifying_question']);
  result.type=validTypes.has(result.type)?result.type:'explanation';result.title=String(result.title??'Nuru explanation').slice(0,100);result.content=String(result.content??'').slice(0,1200);result.followUps=Array.isArray(result.followUps)?result.followUps.filter(x=>typeof x==='string').slice(0,3):[];if(mode==='assessment')delete result.temporaryPractice;
  const {data:log,error:logError}=await admin.from('nuru_interactions').insert({school_id:schoolId,student_id:studentId,course_id:context.currentCourse?.id??null,content_node_id:context.currentLesson?.id??null,assessment_attempt_id:assessment?.id??null,interaction_type:interactionType,mode,hint_level:chosen==='hint'?level:0,student_question:question,response_summary:result.content,provider:'openai',model:Deno.env.get('NURU_AI_MODEL')??'gpt-4o-mini'}).select('id').single();
  if(logError)throw new Error('Interaction log failed');
  console.info(JSON.stringify({level:'info',event:'nuru_success',requestId,userId:user.id,schoolId,mode,timestamp:new Date().toISOString()}));
  return respond({...result,interactionId:log.id,mode,hintLevel:chosen==='hint'?level:undefined,restricted});
 }catch(error){console.error(JSON.stringify({level:'error',event:'nuru_failure',requestId,message:error instanceof Error?error.message:'unknown',timestamp:new Date().toISOString()}));return respond({error:'Nuru could not respond right now. Your lesson is still available.'},503)}
});
