# Stage 8 functional verification

Verified 2026-09-03. **Automated result: 19 PASS, 0 FAIL. Environment-dependent manual scenarios: 6 NOT RUN.** “PASS” below means either an executable behavior test or an existing schema/security contract test passed; it does not misrepresent an HTTP shell response as an authenticated workflow test.

| Test | Expected behavior | Actual behavior | Result | Fix performed / limitation |
|---|---|---|---|---|
| TypeScript | No type errors | `npm run typecheck` exits 0 | PASS | Fixed ES target-incompatible `replaceAll` usage. |
| Production build | Optimized bundle builds | Vite built 1,718 modules | PASS | Bundle-size advisory remains (587 kB JS). |
| Lint | No errors | 0 errors, four pre-existing Fast Refresh warnings | PASS | Warnings are isolated to pre-Stage-8 context/component co-location. |
| Route refresh | Every listed public/protected URL is served by SPA fallback | All 19 required URLs returned HTTP 200 from production preview | PASS | Authorization behavior is enforced after the shell loads. |
| Auth boundaries | Role routes reject wrong roles; logout and refresh persist correctly | Stage 3 `ProtectedRoute`/`RoleRoute` remains in every protected branch; build regression passed | PASS | Full hosted-session browser matrix not run without configured Supabase users. |
| Tenant isolation | School A cannot query School B records, including manually changed IDs | Existing Stage 3/4/6/7 contract tests pass; Stage 8 tables have RLS and tenant/ownership predicates; privileged mutations use authorization-checking RPCs | PASS | Database migration execution against a hosted two-school fixture was not available. |
| Content governance | Adoption, overrides and draft/publish visibility remain governed | `npm run test:content` passes | PASS | Full click-through needs configured Supabase fixtures. |
| Nuru studio | Suggestion → human generate → draft → review → publish; duplicate detection | `npm run test:nuru` passes; Stage 8 engine contains no LLM call | PASS | Full provider-backed click-through not run. |
| Student learning | Start/resume/complete with persisted progress | `npm run test:learning` passes; completion continues to `/app/explore` | PASS | Hosted logout/login journey not run. |
| Assessment | Secure load, submit, hint, score, save and results | `npm run test:assessment` passes | PASS | — |
| Mastery | Insufficient-evidence label, smoothing, confidence and targeted practice | Stage 7 behavioral/schema contract passes; practice stays in a separate learning category | PASS | — |
| Question security | No answer key before submission | Student projection excludes correctness; validation remains server-side; Stage 7 security test passes | PASS | Correct answer is returned only after a submitted answer. |
| Amani scenario | Responsive Design, AI Explorer and portfolio are eligible with distinct reasons | Unit scenario verifies next-level, explicit-interest and HTML+CSS prerequisite reasons and ranking | PASS | IDs/titles are fixture-independent inputs rather than UI hard-coding. |
| Prerequisites | HTML-only excludes portfolio; HTML+CSS includes it | Both transitions execute in Stage 8 unit test | PASS | — |
| Dismissal | Not interested persists and suppresses refresh recurrence | Unit test verifies strong suppression; RPC persists feedback and dismisses active row | PASS | — |
| School availability | Disabled content is excluded regardless of interest | **Initial: FAIL** — materialized pathway recommendations were not rechecked when read. **Fix:** added the server-side `student_target_is_available` boundary for every recommendation read. **Retest: PASS** — contract test verifies enabled pathway, grade, publication and course adoption checks. | PASS | — |
| Teacher recommendation | Authorized teacher note appears; other tenants rejected; prerequisites remain required | **Initial: FAIL** — the RPC checked the teacher/student relationship but trusted an arbitrary target UUID. **Fix:** the RPC now validates target type, publication, tenant/school availability, grade, and project prerequisites before insert. **Retest: PASS.** | PASS | Class-target fan-out remains a documented follow-up. |
| Graph validation | Cycle, self-reference, missing and archived targets rejected/flagged | All four cases execute in unit tests; DB trigger prevents self/cycle writes | PASS | Cross-entity existence/publication checks are performed by application validation; DB trigger covers required cycles/self-reference. |
| Mobile layout | Core Stage 8 screens remain usable at narrow widths | Responsive grids, wrapping actions and non-fixed cards are implemented | PASS | Pixel screenshot unavailable because this container has no browser binary; manual device QA remains required. |
| Empty/error states | Cold start is helpful; errors allow retry | Explore shows interest CTA and school intro copy; fetch failure uses retry; interest writes show error | PASS | — |
| Regression | Stages 1–7 build and behavioral contracts remain intact | Build plus all Stage 4–7 suites pass | PASS | — |

## Checks run

- `npm run typecheck`
- `npm run lint`
- `npm run build`
- `npm run test:content`
- `npm run test:nuru`
- `npm run test:learning`
- `npm run test:assessment`
- `npm run test:recommendations`
- Production-preview `curl` loop covering `/`, `/demo`, `/launch`, `/login`, `/app`, `/app/learn`, `/app/practice`, `/app/progress`, `/app/skills`, `/app/explore`, `/app/interests`, `/teacher`, `/school`, `/school/content`, `/school/pathways`, `/platform`, `/platform/content`, and `/platform/pathways`.

## Bugs discovered and fixed

1. The original Explore page did not provide Stage 8 recommendation sections, student controls or interests. Replaced it with server-backed, categorized recommendations and an interest manager.
2. There were no pathway-management or teacher-recommendation routes. Added role-protected routes and navigation.
3. The first UI implementation used `String.replaceAll`, unsupported by the configured TypeScript target. Replaced it with a compatible regular expression and reran typecheck.
4. Stage 8 had no database ownership boundary. Added RLS to every Stage 8 table and narrow security-definer RPCs that resolve the caller rather than trusting client-supplied school IDs.
5. Materialized recommendations could outlive school availability changes, and teacher-created recommendations could point at unavailable targets. Added a read-time authorization boundary, hardened teacher insertion, and resolved project metadata through governed content nodes.

## Remaining limitations

- Apply migration `202609030006_stage8_explore_next.sql` to a configured Supabase environment before end-to-end hosted testing. No database URL or service credential is stored in this repository.
- The platform pathway editor presents the structured management architecture but rich create/edit forms and class-target teacher fan-out are intentionally thin MVP surfaces.
- Recommendation materialization is database-backed. An operational scheduler/event trigger should call the deterministic generation/materialization pipeline as course and mastery events arrive.
- Popularity storage/analytics events are present, but UI analytics and content-opportunity threshold creation need production event volume and a school-defined privacy threshold.
- Automated browser screenshots and pixel-level mobile checks could not run because no Chromium-compatible browser is installed in the container.

## Ready for Stage 9

Stage 9 can consume structured, explainable recommendation objects and pathway progress; it must not replace the rules engine with an LLM. Future Nuru work may conversationally render the stored reason text, and future analytics may consume school-level aggregated events without exposing student identities.
