export interface MilestoneProgressInput{status:string;project_milestones?:{required:boolean}|null}
export function milestoneProgress(milestones:MilestoneProgressInput[]){const required=milestones.filter(x=>x.project_milestones?.required!==false);const completed=required.filter(x=>x.status==='completed').length;return {completed,total:required.length,percent:required.length?Math.round(completed/required.length*100):0}}
export function canSubmit(milestones:MilestoneProgressInput[]){const progress=milestoneProgress(milestones);return progress.total>0&&progress.completed===progress.total}
