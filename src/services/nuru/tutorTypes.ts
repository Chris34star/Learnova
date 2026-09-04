export type NuruMode='learning'|'practice'|'assessment'|'review'|'explore'|'project';
export type NuruInteractionType='explain'|'simplify'|'example'|'hint'|'mistake'|'practice'|'recommendation'|'compare'|'question';
export type NuruResponseType='explanation'|'hint'|'worked_example'|'mistake_explanation'|'concept_connection'|'practice_prompt'|'recommendation_explanation'|'clarifying_question';
export interface NuruRequest {question:string;interactionType:NuruInteractionType;courseId?:string;contentNodeId?:string;assessmentAttemptId?:string;questionId?:string;recommendationTargetId?:string;studentProjectId?:string;hintLevel?:number}
export interface TemporaryPractice {kind:'temporary_ai_practice';prompt:string;answerToken:string;difficulty:string;skillId?:string}
export interface NuruResponse {interactionId:string;type:NuruResponseType;title:string;content:string;followUps:string[];mode:NuruMode;hintLevel?:number;temporaryPractice?:TemporaryPractice;restricted?:boolean}
