# Stage 6 learning engine

## Safety and availability

Student screens call `student_available_courses()` and `student_course_nodes()` rather than browsing the library. A course and every returned node must be `published` with a non-null approval timestamp. Availability is the union of active school adoption/assignment and tenant-owned, grade-compatible courses. The effective-node function substitutes a published, approved school override; an unavailable override falls back to its global source. RLS remains a second boundary.

## Progress rules and sequence

Required progress nodes are `lesson`, `activity`, `practice`, `project`, `challenge`, and `milestone`. Containers and metadata (`module`, `topic`, `subtopic`, explanations, examples and resources) do not affect the percentage. Next content is the next required node in curriculum order. Course completion is emitted exactly once after every required effective node is complete. Course relationships provide deterministic prerequisite, recommended-after and next-level exploration.

## Active time and resume

The lesson records a section identifier when a component becomes meaningfully visible. Progress saves persist that checkpoint. The client counts active seconds only while interaction occurred in the previous five minutes; it pauses thereafter and resumes after pointer, keyboard, or scroll activity. Each save writes a capped, closed session segment, so an abandoned tab cannot accrue unlimited time. Completion failures remain visible and retryable.

## Boundaries for later stages

Activities are ungraded completion interactions. There is no mastery, weakness inference, adaptive difficulty, live AI tutoring, semantic recommendation, leaderboard, portfolio upload, or public learner data. Nuru receives lesson context but displays only a coming-soon message. Stage 7 can add assessments and mastery calculations on top of the tenant-safe progress/event foundation.
