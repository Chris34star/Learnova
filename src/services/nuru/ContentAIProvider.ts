import type {ContentContext,ContentSuggestion,DraftQuestion,ImprovementProposal,NuruDraft} from './types';

export interface ContentAIProvider {
 readonly name:string;
 suggestContentGaps(context:ContentContext):Promise<ContentSuggestion[]>;
 generateLessonDraft(context:ContentContext,suggestion:ContentSuggestion):Promise<NuruDraft>;
 generateExamples(context:ContentContext,count?:number):Promise<string[]>;
 generatePracticeQuestions(context:ContentContext,count?:number):Promise<DraftQuestion[]>;
 generateQuiz(context:ContentContext,count?:number):Promise<DraftQuestion[]>;
 improveContent(context:ContentContext,current:string,action:string):Promise<ImprovementProposal>;
 generateProject(context:ContentContext,suggestion:ContentSuggestion):Promise<NuruDraft>;
}
