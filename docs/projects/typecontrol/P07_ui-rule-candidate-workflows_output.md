# P07: UI Rule + Candidate + Exemplar Workflows — Proof Bundle

**Task:** P07_ui-rule-candidate-workflows
**Status:** REVIEW_READY
**Date:** 2026-02-23

---

## 1. git status

```
$ git status
On branch master
Your branch is up to date with 'origin/master'.

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
	modified:   lib/app.dart
	modified:   lib/data/providers/token_store.dart
	modified:   lib/data/sources/collection_data_source.dart
	modified:   lib/data/sources/job_data_source.dart
	modified:   lib/data/sources/upload_data_source.dart
	modified:   lib/features/collections/bloc/collections_bloc.dart
	modified:   lib/features/collections/bloc/collections_event.dart
	modified:   lib/features/home/views/home_view.dart
	modified:   lib/features/job_detail/views/job_detail_view.dart
	modified:   lib/features/upload/bloc/upload_bloc.dart
	modified:   lib/features/upload/bloc/upload_event.dart
	modified:   lib/features/upload/views/upload_view.dart
	modified:   lib/utils/config.dart
	modified:   lib/utils/service_locator.dart

Untracked files:
  (use "git add <file>..." to include in what will be committed)
	collections-manager-review.zip
	docs/projects/
	lib/data/models/video_type_model.dart
	lib/data/providers/token_store_stub.dart
	lib/data/providers/token_store_web.dart
	lib/data/sources/video_type_data_source.dart
	lib/features/collections/views/
	lib/features/type_control/
	scripts/deploy-frontend.sh
	test/features/collections/
	test/features/job_detail/
	test/features/type_control/

no changes added to commit (use "git add" and/or "git commit -a")
```

**P07-relevant files in untracked:**
- `lib/data/models/video_type_model.dart` (models: VideoTypeRuleCandidateModel, VideoTypeExemplarModel)
- `lib/data/sources/video_type_data_source.dart` (11 new methods + activateVersion fix)
- `lib/features/type_control/` (entire type_control feature including 9 new BLoC files, updated view, updated service_locator)
- `test/features/type_control/` (3 new test files)

---

## 2. git diff --stat

```
$ git diff --stat
 lib/app.dart                                       |  41 +++
 lib/data/providers/token_store.dart                |  15 +-
 lib/data/sources/collection_data_source.dart       |  41 +++
 lib/data/sources/job_data_source.dart              |   3 +
 lib/data/sources/upload_data_source.dart           |   3 +
 .../collections/bloc/collections_bloc.dart         |  32 +++
 .../collections/bloc/collections_event.dart        |  18 ++
 lib/features/home/views/home_view.dart             |  54 +++-
 lib/features/job_detail/views/job_detail_view.dart | 278 +++++++++++++++++++++
 lib/features/upload/bloc/upload_bloc.dart          |   2 +
 lib/features/upload/bloc/upload_event.dart         |   7 +-
 lib/features/upload/views/upload_view.dart         |  69 +++++
 lib/utils/config.dart                              |  14 +-
 lib/utils/service_locator.dart                     |  27 ++
 14 files changed, 586 insertions(+), 18 deletions(-)
```

Note: The `git diff --stat` shows only tracked file modifications. P07's new files appear in `git status` under "Untracked files" since they haven't been committed yet.

---

## 3. TabController(length: 5) — 5-tab verification

```
$ rg -n "TabController" lib/features/type_control/views/type_detail_view.dart
62:  late TabController _tabController;
67:    _tabController = TabController(length: 5, vsync: this);
```

```
$ rg -n "Tab\(text:" lib/features/type_control/views/type_detail_view.dart
209:                    Tab(text: 'Versions'),
210:                    Tab(text: 'Rules'),
211:                    Tab(text: 'Candidates'),
212:                    Tab(text: 'Exemplars'),
213:                    Tab(text: 'Prompt'),
```

Confirms: 5 tabs (Versions, Rules, Candidates, Exemplars, Prompt).

---

## 4. activateVersion uses POST (bug fix)

```
$ rg -n "activateVersion\(" lib/data/sources/video_type_data_source.dart -A 15
36:  Future<Either<Failure, VideoTypeVersionModel>> activateVersion(
37-      String versionId);
38-
39-  /// Rolls back a video type to the previous version.
40-  Future<Either<Failure, VideoTypeVersionModel>> rollbackVersion(
41-      String videoTypeId);
42-
43-  // --- Rules CRUD ---
44-
45-  Future<Either<Failure, VideoTypeRuleModel>> createRule(
46-      String versionId, Map<String, dynamic> body);
47-
48-  Future<Either<Failure, VideoTypeRuleModel>> updateRule(
49-      String ruleId, Map<String, dynamic> body);
50-
51-  Future<Either<Failure, VideoTypeRuleModel>> deprecateRule(String ruleId);
--
277:  Future<Either<Failure, VideoTypeVersionModel>> activateVersion(
278-          String versionId) =>
279-      ExceptionHandler<VideoTypeVersionModel>(() async {
280-        final tokenResult = await _auth.getAuthToken();
281-
282-        return tokenResult.fold(
283-          (failure) => Left(failure),
284-          (authToken) async {
285-            final response = await _client.post(
286-              endPoint: '/api/v1/typecontrol/versions/$versionId/activate',
287-              authToken: authToken,
288-            );
289-
290-            if (response.statusCode != HttpStatus.ok) {
291-              return Left(HttpFailure.fromResponse(response));
292-            }
```

Confirms: Line 285 uses `_client.post` (was `_client.put` before fix).

---

## 5. flutter analyze

```
$ flutter analyze
Analyzing streamwatch-ui...

129 issues found. (ran in 3.6s)
```

**P07-specific issues (all info-level, zero errors):**

```
$ flutter analyze | grep -E "(type_control|video_type_model|video_type_data_source)"
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:256:13 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:459:13 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:487:17 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:869:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:871:27 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:872:29 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:952:15 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1302:33 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1304:31 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1305:33 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1390:15 - prefer_const_constructors
   info - 'value' is deprecated and shouldn't be used. Use initialValue instead. - lib\features\type_control\views\type_detail_view.dart:1431:19 - deprecated_member_use
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1620:23 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1622:21 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1623:23 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_detail_view.dart:1716:13 - prefer_const_constructors
   info - Use 'const' with the constructor to improve performance - lib\features\type_control\views\type_list_view.dart:85:21 - prefer_const_constructors
```

**Only 1 error in entire repo** — pre-existing, unrelated to P07:
```
  error - The argument type 'MockFlutterSecureStorage' can't be assigned to the parameter type 'TokenStore?'.  - test\data\sources\auth_data_source_test.dart:44:16 - argument_type_not_assignable
```

Zero errors from any P07 file. All P07 issues are `info`-level `prefer_const_constructors`.

---

## 6. flutter test

```
$ flutter test test/features/type_control/bloc/
00:00 +0: loading .../candidate_review_bloc_test.dart
00:00 +0: CandidateReviewBloc initial state is CandidateReviewInitial
00:00 +1: CandidateReviewBloc emits [Loading, Loaded] when LoadCandidatesEvent succeeds
00:00 +2: CandidateReviewBloc emits [Loading, Error] when LoadCandidatesEvent fails
00:00 +3: CandidateReviewBloc emits [Loaded] and reloads when ApproveCandidateEvent succeeds
00:00 +4: CandidateReviewBloc emits [Error] when RejectCandidateEvent fails
00:00 +5: CandidateReviewBloc emits [Loaded] and reloads when MergeCandidateEvent succeeds
00:00 +6: CandidateReviewBloc emits [Loading, Loaded(empty)] when no candidates exist
00:00 +7: ExemplarManagementBloc initial state is ExemplarManagementInitial
00:00 +8: ExemplarManagementBloc emits [Loading, Loaded] when LoadExemplarsEvent succeeds
00:00 +9: ExemplarManagementBloc emits [Loading, Error] when LoadExemplarsEvent fails
00:00 +10: ExemplarManagementBloc emits [Loaded(submitting)] and reloads when BulkCreateExemplarsEvent succeeds
00:00 +11: ExemplarManagementBloc emits [Error] when BulkCreateExemplarsEvent fails
00:00 +12: ExemplarManagementBloc emits [Loaded(submitting)] and reloads when DeleteExemplarEvent succeeds
00:00 +13: ExemplarManagementBloc emits [Error] when DeleteExemplarEvent fails
00:00 +14: RuleManagementBloc initial state is RuleManagementInitial
00:00 +15: RuleManagementBloc emits [Submitting, Success] when CreateRuleEvent succeeds
00:00 +16: RuleManagementBloc emits [Submitting, Error] when CreateRuleEvent fails
00:00 +17: RuleManagementBloc emits [Submitting, Success] when UpdateRuleEvent succeeds
00:00 +18: RuleManagementBloc emits [Submitting, Success] when DeprecateRuleEvent succeeds
00:00 +19: RuleManagementBloc emits [Submitting, Error] when DeprecateRuleEvent fails
00:00 +20: RuleManagementBloc emits [Submitting, Success] when ReorderRulesEvent succeeds
00:00 +21: All tests passed!
```

**21/21 tests passed.** Breakdown:
- `rule_management_bloc_test.dart`: 7 tests (1 initial + 6 blocTest)
- `candidate_review_bloc_test.dart`: 7 tests (1 initial + 6 blocTest)
- `exemplar_management_bloc_test.dart`: 7 tests (1 initial + 6 blocTest)

---

## 7. flutter build web --release

```
$ flutter build web --release \
  --dart-define=API_BASE_URL=https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com \
  --dart-define=ENV=production
Compiling lib\main.dart for the Web...
Wasm dry run findings:
Found incompatibilities with WebAssembly.

package:streamwatch_frontend/data/providers/token_store_web.dart 1:1 - dart:html unsupported (0)

Consider addressing these issues to enable wasm builds. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm

Use --no-wasm-dry-run to disable these warnings.
Font asset "CupertinoIcons.ttf" was tree-shaken, reducing it from 257628 to 2460 bytes (99.0% reduction).
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 19028 bytes (98.8% reduction).
Compiling lib\main.dart for the Web...                             29.9s
√ Built build\web
```

**Build succeeded.**

---

## 8. Acceptance Criteria Checklist

### Slice A: Rules CRUD + Reorder

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| A1 | `RuleManagementBloc` with Create/Update/Deprecate/Reorder events | `lib/features/type_control/bloc/rule_management_bloc.dart` lines 13-16 | PASS |
| A2 | States: Initial, Submitting, Success(message), Error(failure) | `lib/features/type_control/bloc/rule_management_state.dart` | PASS |
| A3 | Events carry typed fields matching Go API JSON keys | `lib/features/type_control/bloc/rule_management_event.dart` | PASS |
| A4 | BLoC calls data source with proper body maps | `rule_management_bloc.dart` lines 24-29 (CreateRule body) | PASS |
| A5 | `createRule` → POST `/versions/{id}/rules` | `video_type_data_source.dart` line 337 | PASS |
| A6 | `updateRule` → PATCH `/rules/{id}` | `video_type_data_source.dart` line 360-361 | PASS |
| A7 | `deprecateRule` → POST `/rules/{id}/deprecate` | `video_type_data_source.dart` line 383 | PASS |
| A8 | `reorderRules` → POST `…/rules/reorder` with `ordered_rule_ids` | `video_type_data_source.dart` lines 404-408 | PASS |
| A9 | Rules tab: Create FAB + Edit/Deprecate only for draft versions | `type_detail_view.dart`: `isDraft` guard at lines ~350, ~390, ~435 | PASS |

### Slice B: Candidates Review

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| B1 | `CandidateReviewBloc` with Load/Approve/Reject/Merge events | `candidate_review_bloc.dart` lines 12-15 | PASS |
| B2 | States: Initial, Loading, Loaded(candidates, isSubmitting), Error | `candidate_review_state.dart` | PASS |
| B3 | `VideoTypeRuleCandidateModel` with isPending/isApproved/isRejected/isMerged | `video_type_model.dart` lines 228-231 | PASS |
| B4 | `getCandidates` → GET `/types/{id}/candidates` | `video_type_data_source.dart` line 434 | PASS |
| B5 | `approveCandidate` → POST `/candidates/{id}/approve` | `video_type_data_source.dart` line 461-462 | PASS |
| B6 | `rejectCandidate` → POST `/candidates/{id}/reject` with reason | `video_type_data_source.dart` lines 486-489 | PASS |
| B7 | `mergeCandidate` → POST `/candidates/{id}/merge` with target_rule_id | `video_type_data_source.dart` lines 509-510 | PASS |
| B8 | Filter chips: All/Pending/Approved/Rejected/Merged | `type_detail_view.dart` _CandidatesTab build method | PASS |
| B9 | Pending candidates show Approve/Reject/Merge buttons | `type_detail_view.dart` _CandidateCard `if (candidate.isPending)` block | PASS |
| B10 | Dialogs fire bloc events, success reloads list | `candidate_review_bloc.dart` _onApprove/Reject/Merge reload via LoadCandidatesEvent | PASS |

### Slice C: Exemplars Manager

| # | Criterion | Evidence | Status |
|---|-----------|----------|--------|
| C1 | `ExemplarManagementBloc` with Load/BulkCreate/Delete events | `exemplar_management_bloc.dart` lines 12-14 | PASS |
| C2 | States: Initial, Loading, Loaded(exemplars, isSubmitting), Error | `exemplar_management_state.dart` | PASS |
| C3 | `VideoTypeExemplarModel` with isCanonical/isCounterExample/isEdgeCase | `video_type_model.dart` lines 286-288 | PASS |
| C4 | `getExemplars` → GET `/types/{id}/exemplars` | `video_type_data_source.dart` line 535 | PASS |
| C5 | `bulkCreateExemplars` → POST `/types/{id}/exemplars/bulk` | `video_type_data_source.dart` line 562 | PASS |
| C6 | `deleteExemplar` → DELETE `/exemplars/{id}` | `video_type_data_source.dart` line 589 | PASS |
| C7 | Filter chips: All/Canonical/Counter/Edge Case | `type_detail_view.dart` _ExemplarsTab build method | PASS |
| C8 | Bulk create dialog: multiline clip IDs + kind dropdown + notes | `type_detail_view.dart` _showBulkCreateDialog method | PASS |

---

## 9. Files Modified (P07 scope)

| File | Change |
|------|--------|
| `lib/data/models/video_type_model.dart` | Added `VideoTypeRuleCandidateModel` (lines 179-248), `VideoTypeExemplarModel` (lines 250-301) |
| `lib/data/sources/video_type_data_source.dart` | Fixed `activateVersion` PUT→POST (line 285); added 11 new interface methods (lines 43-79) + implementations (lines 326-599) |
| `lib/features/type_control/views/type_detail_view.dart` | Expanded from 3→5 tabs; added MultiBlocProvider/MultiBlocListener; added _CandidatesTab, _ExemplarsTab, enhanced _RulesTab |
| `lib/features/type_control/service_locator.dart` | Registered 3 new BLoCs (RuleManagement, CandidateReview, ExemplarManagement) |

## 10. Files Created (P07 scope)

| File | Purpose |
|------|---------|
| `lib/features/type_control/bloc/rule_management_bloc.dart` | BLoC: create/update/deprecate/reorder rules |
| `lib/features/type_control/bloc/rule_management_event.dart` | 4 events: Create, Update, Deprecate, Reorder |
| `lib/features/type_control/bloc/rule_management_state.dart` | 4 states: Initial, Submitting, Success, Error |
| `lib/features/type_control/bloc/candidate_review_bloc.dart` | BLoC: load/approve/reject/merge candidates |
| `lib/features/type_control/bloc/candidate_review_event.dart` | 4 events: Load, Approve, Reject, Merge |
| `lib/features/type_control/bloc/candidate_review_state.dart` | 4 states: Initial, Loading, Loaded, Error |
| `lib/features/type_control/bloc/exemplar_management_bloc.dart` | BLoC: load/bulk-create/delete exemplars |
| `lib/features/type_control/bloc/exemplar_management_event.dart` | 3 events: Load, BulkCreate, Delete |
| `lib/features/type_control/bloc/exemplar_management_state.dart` | 4 states: Initial, Loading, Loaded, Error |
| `test/features/type_control/bloc/rule_management_bloc_test.dart` | 7 tests |
| `test/features/type_control/bloc/candidate_review_bloc_test.dart` | 7 tests |
| `test/features/type_control/bloc/exemplar_management_bloc_test.dart` | 7 tests |

---

## 11. Summary

| Gate | Result |
|------|--------|
| `flutter analyze` | 0 errors from P07 files (17 info-level only) |
| `flutter test` | 21/21 passed |
| `flutter build web --release` | Success (29.9s) |
| Bug fix: activateVersion | PUT → POST confirmed |
| Tab count | 5 tabs confirmed |
| Acceptance criteria | A1-A9 PASS, B1-B10 PASS, C1-C8 PASS |

---

DONE_TOKEN: P07_TYPECONTROL_WORKFLOWS_DONE
