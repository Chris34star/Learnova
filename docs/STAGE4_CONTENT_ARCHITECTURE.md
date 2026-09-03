# Stage 4 governed content architecture

## Inheritance and scope

A school adopts a global course by inserting one `school_course_adoptions` row. No course or tree rows are copied. `effective_course_nodes(school, course)` reads the current global nodes and substitutes an active school node whose `source_content_id` points at that global node. Consequently, unoverridden nodes receive global updates immediately. “Use global version again” archives the override; the resolver then falls back to the source.

Global and school content share `courses`, `content_nodes`, tags, and relationships. The recursive `parent_id` hierarchy is intentionally unconstrained by depth. Academic and Skills Lab are values of `content_family`, while challenges, milestones, and projects are ordinary node types.

## Governance and history

Content follows `draft → in_review → approved → published`; approval and publishing are separate actions. Teachers can create school drafts and submit, but RLS prevents them from approving or publishing. Immutable `content_versions` snapshots keep author, timestamp, summary, status, and revision number. A future rollback creates a new version from an old snapshot rather than destroying history.

Every workflow transition writes a `content_approval_actions` event with actor, time, target, action, and optional note. `content_reviews` stores review decisions independently from the audit stream. School-to-global promotion creates a `content_proposals` record. Acceptance must create a separate global entity with `origin_school_*` provenance; it never changes the tenant-owned source.

## Security boundary

RLS separates school tenants, reserves global writes and proposal decisions for platform administrators, and limits teacher updates to their own drafts/reviews. Students can select only adopted global or own-school nodes that are both published and have an approval timestamp. Learning features should query `student_published_content`, never the authoring tables directly.

## Stage 5 handoff

Structured JSON, objectives, metadata, tags, immutable revisions, and the human review boundary are ready for Nuru drafting and coverage suggestions. Stage 5 must create drafts only and must never bypass review, approval, publishing, RLS, or audit events.
