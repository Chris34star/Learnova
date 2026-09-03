# Stage 7 assessment and mastery model

Learnova treats mastery as a **current instructional indicator**, never permanent ability. Correctness is validated in PostgreSQL; answer keys are excluded from the student question view.

## Incremental algorithm

Each submitted answer maps through `question_skills`. The score begins at a neutral 50 and moves 18% toward 100 for correct evidence or 0 for incorrect evidence. Foundation, developing, proficient and challenge evidence multipliers are 1.0, 1.2, 1.4 and 1.6. A correct answer using a hint targets 90 rather than 100, a small reduction that preserves hints as learning tools. Scores are clamped to 0–100. This exponential smoothing means old errors can be recovered from and one new error cannot collapse a strong estimate.

Levels are tenant-configurable around defaults: Needs Practice 0–39, Developing 40–59, On Track 60–79 and Strong 80–100. Before the configurable minimum (default three attempts), the learner sees **Still learning** regardless of score.

Confidence is separate: `100 × (1 − exp(−evidence_count/6))`, clamped to 100 and displayed as Low (<40), Medium (40–74), or High (75+). It represents evidence volume, not ability.

## Gaps, practice and selection

A rules-engine recommendation is created only when evidence meets the minimum and mastery is below the configurable gap threshold (default 60). The supportive reason is “Recent practice suggests this area could use another round.”

Selection only uses approved, published, tenant-visible questions mapped to the requested skill. Least recently seen and least exposed questions come first. Recent success selects the next adjacent difficulty; difficulty never jumps more than one band. This is intentionally deterministic and is not AI adaptation.

## Security and future context

RLS limits attempts, mastery and recommendations to the learner, authorized class teachers, and narrowly scoped school access. Student delivery projects no `is_correct` or `answer_data_json`; server functions validate and reveal feedback only after submission. Mastery events retain the previous/new score and concise evidence reason for educator explainability.

The normalized mastery and recommendation records provide Stage 8 with structured `strongSkills`, `developingSkills`, and `skillsNeedingPractice`. No LLM is called and no Explore Next decisions are implemented here.
