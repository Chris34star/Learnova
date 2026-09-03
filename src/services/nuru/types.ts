export type NuruScope = 'global' | 'school';
export type SuggestionType = 'missing_content'|'content_improvement'|'practice_gap'|'quiz_gap'|'project_opportunity'|'student_interest'|'low_mastery'|'high_search_interest'|'next_level_opportunity';
export type QuestionType = 'multiple_choice'|'short_answer'|'numeric'|'true_false';

export interface ContentContext { scope:NuruScope; schoolId?:string; courseId?:string; contentNodeId?:string; courseTitle:string; grade?:string; subject?:string; topic:string; subtopic?:string; learningObjectives?:string[]; approvedParentContent?:string; desiredContentType:'academic_lesson'|'practical_project'; difficulty?:string; contentFamily:'academic'|'skills' }
export interface ContentSuggestion { id:string; scope:NuruScope; type:SuggestionType; title:string; description:string; reason:string; priority:'high'|'medium'|'low'; placement:string; objectives:string[]; package:string[]; status:'pending'|'accepted'|'dismissed'|'generated'|'completed' }
export interface DraftQuestion { id:string; question:string; questionType:QuestionType; answer:string; explanation:string; difficulty:string; duplicateOf?:string; duplicateDecision?:'keep'|'remove' }
export interface LessonSection { id:string; heading:string; body:string }
export interface NuruDraft { id:string; generationRequestId:string; title:string; template:'academic'|'practical'; objectives:string[]; sections:LessonSection[]; questions:DraftQuestion[]; quiz:DraftQuestion[]; status:'draft'|'in_review'; scope:NuruScope; schoolName?:string; sourceLabel?:string }
export interface ImprovementProposal { current:string; proposed:string; action:string }
