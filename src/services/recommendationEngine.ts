export type TargetType='course'|'skill'|'content_node'|'pathway'|'project';
export type RecommendationKind='practice'|'next_lesson'|'next_course'|'next_level'|'explore_pathway'|'project'|'teacher_recommended';
export type Candidate={id:string;targetType:TargetType;title:string;description?:string;status:'draft'|'approved'|'published'|'archived';enabled:boolean;minimumGrade?:number|null;maximumGrade?:number|null;interestKeys?:string[];prerequisiteIds?:string[];relationship?:'next_level'|'recommended_after'|'related'|'leads_to_project';relationshipSourceIds?:string[];difficulty?:string;estimatedMinutes?:number;pathwayTitle?:string;teacherName?:string;practiceReason?:string};
export type RecommendationFeedback={targetId:string;type:'interested'|'not_interested'|'maybe_later'|'started'|'completed';createdAt?:string};
export type RecommendationContext={grade?:number|null;completedIds:Set<string>;strongSkillIds?:Set<string>;interestKeys:Set<string>;candidates:Candidate[];feedback?:RecommendationFeedback[];popularTargetIds?:Set<string>};
export type RankedRecommendation={targetId:string;targetType:TargetType;title:string;description:string;recommendationType:RecommendationKind;category:'learning'|'exploration';score:number;reasonCode:string;reasonText:string;difficulty?:string;estimatedMinutes?:number};

export const RECOMMENDATION_WEIGHTS={base:10,prerequisitesSatisfied:30,nextLevel:30,explicitInterest:25,strongSkill:15,related:15,teacher:25,popular:8,maybeLater:-20,notInterested:-100} as const;

export function validateGraph(nodes:{id:string;status?:string}[],edges:{sourceId:string;targetId:string;type:string;required?:boolean}[]):string[]{
 const ids=new Set(nodes.map(n=>n.id)),errors:string[]=[]; const required=new Map<string,string[]>();
 for(const e of edges){if(e.sourceId===e.targetId)errors.push('Self-reference is not allowed.');if(!ids.has(e.sourceId)||!ids.has(e.targetId))errors.push('Relationship contains a missing target.');if(nodes.find(n=>n.id===e.targetId)?.status==='archived')errors.push('Required relationship cannot target archived content.');if(e.required&&nodes.find(n=>n.id===e.targetId)?.status!=='published')errors.push('Required relationship must target published content.');if(e.type==='prerequisite'&&e.required!==false)required.set(e.sourceId,[...(required.get(e.sourceId)??[]),e.targetId]);}
 const visiting=new Set<string>(),done=new Set<string>(); const visit=(id:string):boolean=>{if(visiting.has(id))return true;if(done.has(id))return false;visiting.add(id);for(const next of required.get(id)??[])if(visit(next))return true;visiting.delete(id);done.add(id);return false};
 if(nodes.some(n=>visit(n.id)))errors.push('Circular prerequisite detected.'); return [...new Set(errors)];
}

export function recommend(context:RecommendationContext):RankedRecommendation[]{
 const feedback=context.feedback??[];
 return context.candidates.flatMap((c):RankedRecommendation[]=>{
  if(c.status!=='published'||!c.enabled||context.completedIds.has(c.id))return [];
  if(context.grade!=null&&((c.minimumGrade!=null&&context.grade<c.minimumGrade)||(c.maximumGrade!=null&&context.grade>c.maximumGrade)))return [];
  const prerequisites=c.prerequisiteIds??[]; if(prerequisites.some(id=>!context.completedIds.has(id)))return [];
  const relevant=feedback.filter(f=>f.targetId===c.id);if(relevant.some(f=>f.type==='completed'))return [];
  let score=RECOMMENDATION_WEIGHTS.base,reasonCode='school_available',reasonText='Available through your school as a published learning option.';
  if(prerequisites.length){score+=RECOMMENDATION_WEIGHTS.prerequisitesSatisfied;reasonCode='prerequisites_satisfied';reasonText='You now have the skills needed to try this project.'}
  const sources=(c.relationshipSourceIds??[]).filter(id=>context.completedIds.has(id));
  if(c.relationship==='next_level'&&sources.length){score+=RECOMMENDATION_WEIGHTS.nextLevel;reasonCode='next_level';reasonText=`This is the next level${c.pathwayTitle?` in ${c.pathwayTitle}`:''}.`}
  else if(sources.length){score+=RECOMMENDATION_WEIGHTS.related;reasonCode='completed_related';reasonText='Recommended because it builds on learning you completed.'}
  if((c.interestKeys??[]).some(k=>context.interestKeys.has(k))){score+=RECOMMENDATION_WEIGHTS.explicitInterest;reasonCode='explicit_interest';reasonText=`Recommended because it matches an interest you selected.`}
  if(c.teacherName){score+=RECOMMENDATION_WEIGHTS.teacher;reasonCode='teacher_recommended';reasonText=`Recommended by ${c.teacherName}.`}
  if(c.practiceReason){reasonCode='practice_gap';reasonText=c.practiceReason}
  if(context.popularTargetIds?.has(c.id)){score+=RECOMMENDATION_WEIGHTS.popular;if(reasonCode==='school_available')reasonText='Popular among learners at your school.'}
  score+=relevant.filter(f=>f.type==='maybe_later').length*RECOMMENDATION_WEIGHTS.maybeLater+relevant.filter(f=>f.type==='not_interested').length*RECOMMENDATION_WEIGHTS.notInterested;
  if(score<0)return [];
  return [{targetId:c.id,targetType:c.targetType,title:c.title,description:c.description??'Explore this school-approved learning opportunity.',recommendationType:c.practiceReason?'practice':c.teacherName?'teacher_recommended':c.targetType==='project'?'project':c.targetType==='pathway'?'explore_pathway':c.relationship==='next_level'?'next_level':'next_course',category:c.practiceReason?'learning':'exploration',score,reasonCode,reasonText,difficulty:c.difficulty,estimatedMinutes:c.estimatedMinutes}];
 }).sort((a,b)=>b.score-a.score||a.title.localeCompare(b.title));
}
