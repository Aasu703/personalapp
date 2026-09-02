# SewaSathi Implementation Plan — meroapp (Flutter client)

## 1. Overview

This refactors `meroapp` from a personal tracker (finance, todos, sleep)
into the client for **SewaSathi**, an autonomous citizen-service agent for
Nepal government services. Auth, the Dio client, the app shell, routing,
onboarding, splash — all untouched. Finance, health, and todos are
deleted, not reshaped: 57 files removed, ~44 added, net negative.

**What the UI has to sell is agentic behavior.** A reviewer looking at
this app should immediately read "this is an autonomous case manager,"
not "this is a chatbot." The centerpiece screen is a live agent-activity
timeline — every decision the backend makes, with its reasoning, visible
as it happens.

**This document is the reconciled contract**, resolved against the
backend's actual design in
[`socketTest/docs/sewasathi-implementation-plan.md`](../../socketTest/docs/sewasathi-implementation-plan.md).
It supersedes an earlier, independently-planned client-side draft that
guessed wrong on several wire details. If anything here conflicts with
that backend doc, **the backend doc wins** — it owns the schema.

## 2. Facts verified against source (not against stale docs)

- **`authRepositoryProvider` is wired to `AuthRepositoryImpl`** — the
  custom `socketTest` backend, not Firebase
  (`lib/core/di/providers.dart:46-48`). `CLAUDE.md` is stale on this
  point. Consequence: SewaSathi's authenticated calls already carry a
  valid `Authorization: Bearer` token with refresh-on-401 — nothing to
  fix here. `FirebaseAuthRepositoryImpl` has zero importers; it's dead
  code, delete it (§3.2).
- Also dead, zero importers: `core/media/cloudinary_helper.dart`,
  `core/config/supabase_config.dart`.
- **No responsive-layout convention currently exists** — zero
  `LayoutBuilder`, zero `MediaQuery` breakpoint logic anywhere in `lib/`.
  This plan introduces one (§5.0), deliberately kept to two small files.
- **The use-case layer is vestigial.** `todoProviders`/`financeProviders`
  call the repository directly; the `domain/usecases/*.dart` pass-through
  classes are dead weight nobody calls except in auth. This plan matches
  the pattern actually in use, not the unused one (§4.4) — two pure
  functions, not a use-case class per repository method.
- **No file-picking dependency exists.** `image_picker` must be added for
  document upload — see the risk in §11.
- Route arguments currently pass via
  `ModalRoute.of(context)?.settings.arguments` over a static
  `Map<String, WidgetBuilder>`. Deep-linking `/case/:id` needs
  `onGenerateRoute` instead — the one deliberate deviation from the
  existing convention (§7.3), because a case must be addressable by id
  whether it's the full screen or an embedded pane.

## 3. Deletion list

### 3.1 Directories — delete wholesale (54 files)

```
lib/features/finance/          (18 files)
lib/features/health/           (17 files)
lib/features/todos/            (14 files)
lib/features/home/             (1 file — see note)
```

`lib/features/home/presentation/home_screen.dart` goes too: the case
dashboard lives in `features/cases/` next to its own providers, and
`RoutePaths.home` is repointed at it. This keeps splash
(`splash_screen.dart:69`) and login navigation untouched — zero edits to
the auth feature.

### 3.2 Free dead-code sweep (zero importers, verified)

```
lib/core/media/cloudinary_helper.dart          — unused; also the only `http` MultipartRequest path, which would otherwise compete with Dio for uploads
lib/core/config/supabase_config.dart           — unused
lib/features/auth/data/repositories/firebase_auth_repository_impl.dart  — orphaned second auth impl
```

Deleting the Firebase repo lets `firebase_auth`, `google_sign_in`,
`supabase_flutter`, `http`, `cloud_firestore` leave `pubspec.yaml`.
**Do not remove `firebase_core`** — `lib/bootstrap.dart:22` still calls
`Firebase.initializeApp` and `lib/firebase_options.dart` is wired into
`android/` + `ios/` config. Out of scope for this refactor.

### 3.3 Exact unwiring

**`lib/core/di/providers.dart`** — delete the finance/todos/sleep
imports and the entire `// ---- Features ----` block
(`sleepRepositoryProvider`, `todoRepositoryProvider`,
`financeRepositoryProvider`). Replace per §7.1.

**`lib/app/routes/app_routes.dart`** — delete the finance/health/home/todos
imports and their route-map entries. Replace per §7.3.

**`lib/core/constants/route_paths.dart`** — delete `health`, `healthLog`,
`sleepHistory`, `todos`, `todosAdd`, `finance`, `financeAdd`,
`financeHistory`. **Keep `home`** — it's repointed, not removed.

**`lib/core/network/api_client.dart`** — the `_asItemList` key list:

```dart
// before
for (final key in const ['items', 'results', 'logs', 'todos', 'transactions']) {

// after
for (final key in const ['items', 'results', 'cases', 'actions', 'documents', 'services', 'tasks']) {
```

These are the exact named keys the backend's envelope uses (§6) — verify
against `sewasathi-implementation-plan.md` in `socketTest` if the backend
contract changes.

**`lib/bootstrap.dart`**, **`lib/main.dart`, `main_local.dart`,
`main_staging.dart`, `main_production.dart`** — no changes. Verified they
only touch `dioProvider`/`sessionStoreProvider`/`secureStorageProvider`/
`currentUserProvider` and call `AppConfig.load` + `bootstrap()`.

**`lib/app/app.dart`** — `title: 'MeroApp'` → `'SewaSathi'`. Add
`onGenerateRoute` per §7.3.

**Tests** — `test/widget_test.dart` has zero references to the deleted
features (verified). No edit needed.

**Docs** — `README.md`, `docs/implementation-plan.md` (this file
supersedes it — consider deleting or archiving the old one once this
refactor lands), and the feature-route section of `docs/coordination.md`
all describe finance/todos/health. Update `docs/coordination.md`
alongside the backend's mirror (§12).

**`pubspec.yaml`** — remove `firebase_auth`, `google_sign_in`,
`supabase_flutter`, `http`, `cloud_firestore`. Add `image_picker: ^1.1.2`.
No other additions — `dio`, `intl`, `flutter_riverpod`, `talker` already
cover everything needed.

**Gate:** `flutter analyze` must be clean (0 issues) after these edits —
nothing outside the files above references the deleted trees.

## 4. Domain layer

Three feature modules, each earning its module status for a specific
reason:

- **`cases`** — the case aggregate: plan, applications, blocked reason,
  pending approval. All read from and mutated through the same
  `/api/cases` resource, so splitting them into separate repositories
  would just mean four things that always load together.
- **`documents`** — the only sub-domain with its own lifecycle
  (upload → extract → verify) and its own transport concern (multipart),
  so it earns a module.
- **`intake`** — presentation-only, no domain/data layer. It produces a
  `CitizenCase` via one repository call. A repository with one method is
  not a module.

Explicitly **not** modules: escalation state (a case field + timeline
filter, no separate entity beyond what §4.1 already carries) and the
cross-case action-required list (a filtered case query, §4.1).

### 4.1 `features/cases/domain/entities/`

**`citizen_case.dart`** — mirrors the backend `Case` shape exactly
(§6 of the backend plan). This is the authoritative source; do not invent
extra client-side states.

```dart
enum CaseStatus { intake, planning, active, blocked, completed, cancelled }
// parser: unknown string -> CaseStatus.intake (safe fallback, never throws)

extension CaseStatusX on CaseStatus {
  bool get isAgentWorking => this == intake || this == planning;
  bool get isTerminal => this == completed || this == cancelled;
  String get label; IconData get icon;
}

class BlockedReason {
  final String kind; // "citizen" | "officer"
  final String message;
  final String? pendingActionId;
  final String? officerTaskId;
}

class CasePlanStep {
  final String serviceId, serviceName;
  final int order;
  final List<String> dependsOn; // serviceCodes
  final String? applicationId;
}

class CasePlan { final String? journeyId; final List<CasePlanStep> steps; }

class CitizenCase {
  final String id, citizenId, goal;
  final String? intentCode, intentLabel; final double? intentConfidence;
  final String? district;
  final CaseStatus status;
  final BlockedReason? blockedReason;
  final CasePlan plan;
  final DateTime createdAt, updatedAt;
  // const constructor + copyWith, matching the existing Todo entity style
}
```

**`service_application.dart`**

```dart
enum ApplicationStatus {
  awaitingDocuments, ready, submitted, underReview,
  actionRequired, approved, rejected,
}
// wire values are snake_case ("awaiting_documents") — the fromJson parser
// maps the snake_case string to this enum explicitly. Do NOT rely on
// enum.name; write the mapping table.

extension ApplicationStatusX on ApplicationStatus {
  bool get isTerminal => this == approved || this == rejected;
}

class RequirementItem {
  final String key, label, documentType;
  final bool mandatory;
  final List<String> expectedFields;
  final String status; // "missing" | "satisfied" | "rejected"
  final String? documentId, issue;
}

class SubmissionInfo {
  final String reference, officeName;
  final DateTime submittedAt, expectedDecisionAt;
  final int queuePosition;
}

class OfficerDecision {
  final String outcome; // "approved" | "rejected" | "action_required"
  final String reason, decidedBy;
  final DateTime decidedAt;
  final List<String> missingRequirementKeys;
}

class ServiceApplication {
  final String id, caseId, serviceId, serviceName, agency;
  final ApplicationStatus status;
  final double feesNpr;
  final List<RequirementItem> requirements;
  final SubmissionInfo? submission;
  final OfficerDecision? decision;
  final DateTime createdAt, updatedAt;
}
```

**`agent_action.dart`** — the timeline entity.

```dart
enum AgentActionType {
  caseStarted, intentClassified, planCreated, decision,
  toolInvoked, documentUploaded, documentVerified,
  approvalRequested, approvalDecided, applicationCreated,
  applicationSubmitted, statusSynced, escalated,
  officerResolved, caseCompleted, error,
}
// wire values snake_case ("tool_invoked"); parser falls back to a neutral
// default so an unrecognized backend type never crashes the timeline.

class AgentToolCall {
  final String name;
  final Map<String, dynamic>? input, output;
  final int? durationMs;
  final String? error;
}

class AgentActionRefs {
  final String? applicationId, documentId, officerTaskId;
}

class AgentActionApproval {
  final bool required;
  final String status; // "pending" | "approved" | "rejected"
  final String? decidedBy, note;
  final DateTime? decidedAt;
}

class AgentAction {
  final String id, caseId, actor; // actor: "agent" | "citizen" | "officer" | "system"
  final int seq;                  // the cursor — NOT a timestamp
  final AgentActionType type;
  final String summary;
  final String? reasoning;
  final AgentToolCall? tool;
  final AgentActionRefs refs;
  final AgentActionApproval? approval;
  final DateTime createdAt;
}
```

**`case_document.dart`** (lives in `features/documents/`, listed here for
completeness of the case-adjacent picture — see §4.2):

```dart
enum DocumentVerdict { pending, valid, missingFields, wrongType, expired, unreadable }
extension DocumentVerdictX on DocumentVerdict {
  bool get isBlocking => this != valid;
}
```

### 4.2 `features/documents/domain/entities/`

**`case_document.dart`**

```dart
class ExtractedField { final String name; final String? value; final double confidence; }

class CaseDocument {
  final String id, caseId;
  final String? applicationId;
  final String declaredType;
  final String? detectedType;
  final String originalName, mimeType;
  final int sizeBytes;
  final List<ExtractedField> extractedFields;
  final DateTime? issuedAt, expiresAt;
  final double extractionConfidence;
  final DocumentVerdict verdict;
  final DateTime uploadedAt;
}
```

Requirements are **not** a separate fetch — they come embedded on
`ServiceApplication.requirements` (§4.1). `document_requirement.dart` is
therefore **not needed as a standalone entity**; use `RequirementItem`
directly. (This corrects an earlier draft that assumed a dedicated
`GET /requirements` endpoint — the backend embeds them.)

### 4.3 Abstract repositories

```dart
// features/cases/domain/repositories/case_repository.dart
abstract class CaseRepository {
  Future<List<CitizenCase>> getCases({CaseStatus? status});
  Future<CitizenCase> createCase({required String goal, String? district});
  Future<CaseDetail> getCase(String caseId); // case + applications + documents + pendingApproval + officerTasks
  Future<AdvanceResult> advanceCase(String caseId, {int? maxSteps});
  Future<TimelinePage> getTimeline(String caseId, {int sinceSeq = 0, int limit = 50});
  Future<ApproveActionResult> approveAction(String caseId, String actionId, {required bool approved, String? note});
}

class CaseDetail {
  final CitizenCase caseData;
  final List<ServiceApplication> applications;
  final List<CaseDocument> documents;
  final AgentAction? pendingApproval;
  final List<Map<String, dynamic>> officerTasks; // typed fully only if the escalation screen needs more than reason/status
}

class AdvanceResult {
  final CitizenCase caseData;
  final List<ServiceApplication> applications;
  final List<AgentAction> actions; // only the actions appended THIS run
  final String stopReason; // "awaiting_citizen" | "awaiting_officer" | "completed" | "idle" | "max_steps"
}

class TimelinePage { final List<AgentAction> actions; final int nextSeq; }

class ApproveActionResult { final AgentAction action; final CitizenCase caseData; }
```

```dart
// features/documents/domain/repositories/document_repository.dart
abstract class DocumentRepository {
  Future<List<CaseDocument>> getDocuments(String caseId);
  Future<CaseDocument> uploadDocument({
    required String caseId,
    required String declaredType,
    required String filePath,
    String? applicationId,
    String? requirementKey,
    void Function(int sent, int total)? onProgress,
  });
}
```

No `deleteDocument` — not in the backend contract. Don't build a client
method for an endpoint that doesn't exist.

### 4.4 Use cases — deliberately minimal

Matching the pattern actually live in this codebase (§2): feature
providers call repositories directly. Only two pure functions earn a
file, because they're the only real branching logic worth unit-testing
in isolation:

```dart
// features/cases/domain/usecases/case_progress.dart
class CaseProgress {
  final int completedServices, totalServices;
  final ServiceApplication? nextService;
  double get fraction;
}
CaseProgress computeCaseProgress(CitizenCase c, List<ServiceApplication> apps);

// features/documents/domain/usecases/missing_requirements.dart
List<RequirementItem> missingRequirements(List<ServiceApplication> apps);
// mandatory items with status != "satisfied", flattened across all applications in the case
```

No `ListCases`, `CreateCase`, `AdvanceCase`, `UploadDocument` pass-through
classes — they'd just forward to the repository, exactly like the dead
`todos/domain/usecases/*` files this plan deletes. Add one the day it
gains logic beyond forwarding.

## 5. Presentation

### 5.0 Responsive foundation (2 new files, no package)

```dart
// core/layout/window_size.dart
enum WindowSizeClass { compact, medium, expanded, large, extraLarge }
// from(double width): <600 compact, <840 medium, <1200 expanded, <1600 large, else extraLarge
// of(BoxConstraints c) => from(c.maxWidth)  — always derive from LayoutBuilder constraints,
// never MediaQuery.sizeOf, so a widget inside an embedded pane resolves its OWN class.

extension WindowSizeClassX on WindowSizeClass {
  bool get isAtLeastExpanded; bool get isCompact;
}
```

```dart
// core/widgets/content_pane.dart
// Center + ConstrainedBox(maxWidth: 720) — caps reading width on tablet/desktop
// so the plan list and timeline don't run full-bleed on a 1600dp window.
```

Rejected: `responsive_framework`, any `width * 0.4` sizing. Branch on
width only — never `Platform.is*` or `orientationOf`.

### 5.1 Screens

**`intake/presentation/screens/intake_screen.dart`** —
`ConsumerStatefulWidget`. Not a chat log — a single briefing card: "What
do you need to get done?", a 4-line multiline `TextField`, suggestion
chips in Nepali + English ("मलाई काठमाडौंमा सानो व्यवसाय दर्ता गर्नु छ",
"Register a small business in Kathmandu"), and a full-width
`AppPrimaryButton` reusing the existing shared widget. Below the
composer: a static three-step preview ("1. I identify the services 2. I
check your eligibility 3. I prepare and file") to frame this as briefing
a case manager, not chatting with a bot. On submit: `createCase`, then
`pushReplacementNamed` straight into case detail so the citizen lands on
the live agent plan.

**`cases/presentation/screens/case_dashboard_screen.dart`** (replaces
`HomeScreen` at `RoutePaths.home`) — `LayoutBuilder` at the root:
- compact/medium: `ListView.builder` of `CaseProgressCard`,
  `FloatingActionButton` → intake, an app-bar badge → the action-required
  view, the existing logout `IconButton` lifted from the old
  `home_screen.dart`.
- expanded+: two-pane `Row` — 360dp fixed-width case list left,
  `CaseDetailScreen(caseId: selected, embedded: true)` right, driven by
  `selectedCaseIdProvider`. Tap sets the provider on wide, `pushNamed` on
  narrow.
- `RefreshIndicator` → `ref.invalidate(casesProvider)`.

**`cases/presentation/screens/case_detail_screen.dart`** — the money
screen. `ConsumerWidget(caseId, embedded: bool)`. In order:
1. `AgentStatusBanner` — visible only while `status.isAgentWorking`.
2. Header: the citizen's own goal text, district, `CaseProgress` bar.
3. `EscalationBanner` — only when `blockedReason?.kind == "officer"`.
4. `ServicePlanList` — the plan in order, with each step's rationale.
5. If `blockedReason?.kind == "citizen"`: a single prominent action card
   naming what's needed (upload a document, approve a submission) —
   there is no separate `RequiredAction` list on the backend; this state
   comes straight from `case.blockedReason` and, when it names a pending
   approval, `pendingApproval`.
6. `AgentTimeline` — the rest of the scroll, newest-first.

At expanded+, plan and timeline sit side by side inside `LayoutBuilder`
(plan 400dp left, timeline `Expanded` right); at compact they stack in
one `CustomScrollView`. Same child widgets in both arrangements — no
forked tree.

**`cases/presentation/screens/action_required_screen.dart`** — cross-case
list from `GET /api/cases?status=blocked`. Grouped by case, each row
shows `blockedReason.message` and routes into that case's detail screen
rather than trying to act inline — the action always needs case context
(which document, which approval) that only the detail screen has fully
loaded.

**`documents/presentation/screens/documents_screen.dart`** — per case.
Two sections built from `missingRequirements()` and the case's
`documents` list: "Still needed" (each with an upload button prefilled
with `requirementKey`) and "Uploaded" (`DocumentVerdictTile` per doc).
FAB opens `DocumentUploadSheet`.

**`cases/presentation/screens/escalation_screen.dart`** — thin.
`blockedReason.message`, and the timeline filtered to
`escalated`/`officerResolved` events (`AgentTimeline(filter: {...})` —
same widget, not a second one), plus a plain-language "what happens
next" line.

### 5.2 Widgets worth extracting

**`cases/presentation/widgets/agent_timeline.dart`** — the centerpiece
and the only widget with real complexity.
`AgentTimeline({required List<AgentAction> actions, bool isWorking, Set<AgentActionType>? filter})`.
Per node: a vertical rail with a filled circle carrying a per-type icon
(one `switch` expression mapping `AgentActionType` → icon + color),
`summary` bold, `actor` + relative time in a small label, `reasoning`
behind a collapsed disclosure so the rail stays scannable at a glance.
`tool.error` renders as a distinct error-colored line when present. Nodes
are `const`-constructible, each wrapped in `RepaintBoundary` so an
animated head node doesn't repaint the whole rail. No fixed heights
anywhere — survives 200% text scaling. `MergeSemantics` per node.

**`cases/presentation/widgets/agent_status_banner.dart`** — the
"thinking" state: three pulsing dots (single `AnimationController` +
`TweenSequence`), honors
`MediaQuery.disableAnimationsOf(context)` by swapping to a static
indeterminate bar, `Semantics(liveRegion: true)` so the change is
announced.

**`cases/presentation/widgets/case_progress_card.dart`**,
**`service_plan_list.dart`** (draws `dependsOn` as an indent + caption,
not a graph widget — not worth it for a 4-5 node plan),
**`escalation_banner.dart`**,
**`documents/presentation/widgets/document_verdict_tile.dart`**,
**`document_upload_sheet.dart`** — as scoped above.

`core/widgets/status_pill.dart` — one shared primitive generalized from
the existing `PriorityBadge`: `StatusPill({required String label,
required Color background, required Color foreground, IconData? icon})`.
Both `CaseStatus` and `ApplicationStatus` map into it via a per-enum
extension in their own entity file, so `core` stays feature-agnostic.

### 5.3 Adaptive behavior

`Switch.adaptive` / `CircularProgressIndicator.adaptive` /
`AlertDialog.adaptive` for confirms (the existing raw `AlertDialog` in
the deleted todos feature is not a pattern to carry forward). Branch on
`Theme.of(context).platform`, never `dart:io`. All tap targets ≥48dp.
Hover states on desktop/web via `MouseRegion`; `Focus`-traversable
disclosure rows.

### 5.4 Providers — every one, by name and shape

```dart
// features/cases/presentation/providers/case_providers.dart

final casesProvider = FutureProvider.autoDispose<List<CitizenCase>>(
  (ref) => ref.watch(caseRepositoryProvider).getCases(),
);

final caseFilterProvider = StateProvider<CaseStatus?>((ref) => null);

/// Two-pane selection on expanded+ windows. Null = empty-state pane.
final selectedCaseIdProvider = StateProvider<String?>((ref) => null);

/// Case detail state. Reloads on demand — see caseTimelineProvider for
/// the piece that actually polls.
final caseDetailProvider = FutureProvider.autoDispose.family<CaseDetail, String>(
  (ref, caseId) => ref.watch(caseRepositoryProvider).getCase(caseId),
);

/// Polls the audit log ONLY — not the full case state (the backend
/// deliberately splits these two; see §6). Fast while working, slower
/// once idle, stops at terminal. Accumulates newest-first, deduped by
/// nextSeq so nothing re-downloads.
final caseTimelineProvider =
    StreamProvider.autoDispose.family<List<AgentAction>, String>((ref, caseId) async* {
  final repo = ref.watch(caseRepositoryProvider);
  var actions = <AgentAction>[];
  var sinceSeq = 0;
  while (true) {
    final page = await repo.getTimeline(caseId, sinceSeq: sinceSeq, limit: 50);
    if (page.actions.isNotEmpty) {
      actions = [...page.actions.reversed, ...actions]; // newest-first
      sinceSeq = page.nextSeq;
    }
    yield actions;
    // Re-check the case's own status via caseDetailProvider's cached
    // value to decide cadence/stop — the timeline stream itself doesn't
    // know terminality, the case does.
    final detail = ref.read(caseDetailProvider(caseId)).valueOrNull;
    if (detail != null && detail.caseData.status.isTerminal) return;
    await Future<void>.delayed(
      (detail?.caseData.status.isAgentWorking ?? true)
          ? const Duration(seconds: 2)
          : const Duration(seconds: 10),
    );
  }
});

/// Fires POST /advance without blocking the UI thread on the full loop.
/// On completion, invalidates caseDetailProvider(caseId) so status/plan
/// refresh, and returns stopReason for the caller to act on.
final advanceCaseControllerProvider =
    AsyncNotifierProvider.autoDispose.family<AdvanceCaseController, void, String>(
        AdvanceCaseController.new);
// AdvanceCaseController.run() -> Future<String> (stopReason), sets AsyncLoading
// while in flight, invalidates caseDetailProvider + triggers one immediate
// timeline poll on completion so the UI doesn't wait a full interval.

final pendingCasesProvider = FutureProvider.autoDispose<List<CitizenCase>>(
  (ref) => ref.watch(caseRepositoryProvider).getCases(status: CaseStatus.blocked),
);

final intakeControllerProvider =
    AsyncNotifierProvider.autoDispose<IntakeController, void>(IntakeController.new);
// IntakeController.submit(String goal, {String? district}) -> Future<CitizenCase>;
// AsyncLoading during the call, invalidates casesProvider, returns the case.

final approveActionControllerProvider =
    AsyncNotifierProvider.autoDispose.family<ApproveActionController, void, String>(
        ApproveActionController.new);
// .approve(String actionId, {required bool approved, String? note}) -> Future<void>;
// invalidates caseDetailProvider(caseId) on success.
```

```dart
// features/documents/presentation/providers/document_providers.dart

final caseDocumentsProvider = FutureProvider.autoDispose.family<List<CaseDocument>, String>(
  (ref, caseId) => ref.watch(documentRepositoryProvider).getDocuments(caseId),
);

/// Derives from caseDetailProvider's applications, not a separate fetch —
/// requirements are embedded (§4.2).
final missingRequirementsProvider =
    Provider.autoDispose.family<AsyncValue<List<RequirementItem>>, String>((ref, caseId) {
  final detail = ref.watch(caseDetailProvider(caseId));
  return detail.whenData((d) => missingRequirements(d.applications));
});

final uploadProgressProvider = StateProvider.autoDispose<double?>((ref) => null);

final documentUploadControllerProvider =
    AsyncNotifierProvider.autoDispose<DocumentUploadController, void>(DocumentUploadController.new);
// On success: invalidates caseDocumentsProvider(caseId) AND caseDetailProvider(caseId)
// (a satisfied requirement changes application status) — do not forget the second one.
```

`AsyncNotifier` for controllers, matching Riverpod 2 idiom — the codebase
has no `StateNotifier` precedent to preserve.

## 6. Backend contract — what this plan depends on

This is the reconciled contract from
`socketTest/docs/sewasathi-implementation-plan.md` §8. Treat that
document as authoritative if the two ever drift; update this section to
match, not the other way around.

- Base `/api`, envelope `{ success, message, data? }` everywhere.
- Bearer auth on every case/document/service route. **No CSRF header on
  any of them** — verified against the backend's actual middleware.
- **Every list nests under a named key.** `data: { "cases": [...] }`,
  never a bare array. This is why `api_client.dart`'s `_asItemList` key
  list must include `cases`, `actions`, `documents`, `services`, `tasks`
  (§3.3).
- **Enum values are `snake_case` on the wire** (`awaiting_documents`,
  `tool_invoked`). Client parsers must map these explicitly, not rely on
  `EnumName.name`.
- **The audit trail cursor is an integer `seq`, monotonic per case** —
  not a timestamp. `GET /timeline?sinceSeq=N` returns only actions with
  `seq > N`, plus `nextSeq` to pass on the following poll.
- **Case state and the audit log are two separate endpoints**
  (`GET /cases/:id` vs. `GET /cases/:id/timeline`) — the backend
  deliberately did not fuse them into one payload, so poll them at
  different cadences: case state on a normal request cycle, timeline on
  the fast loop (§5.4).
- **`POST /cases` returns immediately** with `status: "planning"`;
  planning happens asynchronously and surfaces through polling. This is
  load-bearing for the entire "watch it think" UX — if this ever becomes
  a blocking call, the whole design changes.
- **`POST /advance` triggers the agent loop and also returns
  reasonably promptly** (bounded by `maxSteps`, not by how slow a model
  call is) — but a slow real model adapter can still exceed the shared
  Dio `receiveTimeout` (20s). Override per-request:
  `Options(receiveTimeout: const Duration(seconds: 90))` on this one
  call. Never loosen the global timeout for the other 8 endpoints.
- **Submission requires an explicit approval action**, not a raw
  "submit" call — `POST /cases/:caseId/actions/:actionId/approve` with
  `{ approved: true }` against the `pendingApproval` action id from
  `GET /cases/:caseId`. There is no separate "submit application"
  endpoint on the client side.
- **`/api/officer/*` is not a mobile surface.** It uses `X-Officer-Key`,
  not the bearer token. Do not wire it into this app.

### Full endpoint list this client calls

| Method | Path | Client repository method |
|---|---|---|
| `POST` | `/api/cases` | `CaseRepository.createCase` |
| `GET` | `/api/cases?status=` | `CaseRepository.getCases` |
| `GET` | `/api/cases/:caseId` | `CaseRepository.getCase` |
| `POST` | `/api/cases/:caseId/advance` | `CaseRepository.advanceCase` |
| `GET` | `/api/cases/:caseId/timeline?sinceSeq=&limit=` | `CaseRepository.getTimeline` |
| `POST` | `/api/cases/:caseId/actions/:actionId/approve` | `CaseRepository.approveAction` |
| `POST` | `/api/cases/:caseId/documents` (multipart) | `DocumentRepository.uploadDocument` |
| `GET` | `/api/cases/:caseId/documents` | `DocumentRepository.getDocuments` |

`GET /api/services` and `GET /api/services/:id` are **not** called by
this client in the flagship build — the catalogue is browsed
server-side/agent-side only. Add a browse screen later if wanted; it's a
two-file addition (`services_screen.dart` + a `FutureProvider`), not
worth speccing now.

## 7. DI + routing

### 7.1 `lib/core/di/providers.dart`

Replace the deleted finance/todos/sleep imports with:

```dart
import '../../features/cases/data/repositories/case_repository_impl.dart';
import '../../features/cases/domain/repositories/case_repository.dart';
import '../../features/documents/data/repositories/document_repository_impl.dart';
import '../../features/documents/domain/repositories/document_repository.dart';
```

Replace the deleted feature-provider block with:

```dart
// ---- SewaSathi ----
final caseRepositoryProvider = Provider<CaseRepository>(
  (ref) => CaseRepositoryImpl(ref.watch(dioProvider)),
);

final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => DocumentRepositoryImpl(ref.watch(dioProvider)),
);
```

Nothing else changes. `dioProvider`, `sessionStoreProvider`,
`currentUserProvider`, and every auth provider stay exactly as they are.

### 7.2 `main*.dart` / `bootstrap.dart`

**No changes.** `bootstrap()` overrides only `secureStorageProvider`,
`sessionStoreProvider`, `dioProvider` — both new repositories resolve
from `dioProvider` with no override needed.

### 7.3 Routing

`lib/core/constants/route_paths.dart` — after the deletions in §3.3, add:

```dart
static const home = '/home';        // now the case dashboard
static const intake = '/intake';
static const caseDetail = '/case';  // + '/<id>'
static const actions = '/actions';
static const documents = '/documents'; // + '/<caseId>'
static const escalation = '/escalation'; // + '/<caseId>'
```

`lib/app/routes/app_routes.dart` — static map keeps the argument-less
routes:

```dart
RoutePaths.home:    (_) => const CaseDashboardScreen(),
RoutePaths.intake:  (_) => const IntakeScreen(),
RoutePaths.actions: (_) => const ActionRequiredScreen(),
```

Plus a new `static Route<dynamic>? onGenerateRoute(RouteSettings settings)`
handling the three id-bearing paths **by path segment**, not
`settings.arguments`:

```
'/case/abc123'       -> CaseDetailScreen(caseId: 'abc123')
'/documents/abc123'  -> DocumentsScreen(caseId: 'abc123')
'/escalation/abc123' -> EscalationScreen(caseId: 'abc123')
```

This is the one deliberate deviation from the existing
`ModalRoute...arguments` convention (§2) — parsing the id out of the path
is what makes case detail addressable whether it's a full screen or an
embedded pane on wide layouts. `lib/app/app.dart` gains
`onGenerateRoute: AppRoutes.onGenerateRoute` alongside the existing
`routes:` map, plus the title change to `'SewaSathi'`.

### 7.4 Home shell

`features/home/` is deleted; `RoutePaths.home` now resolves to
`CaseDashboardScreen`. Because the constant itself is unchanged,
`splash_screen.dart:69`
(`_loggedIn ? RoutePaths.home : RoutePaths.onboarding`), the login
screen, and the logout flow (now living on the dashboard) all keep
working with zero edits to the auth feature. Onboarding copy in
`features/onboarding/data/models/onboarding_item.dart` currently
describes sleep/todos/finance and needs its items rewritten to the
SewaSathi pitch — that's copy, not structure.

## 8. Agent-activity UX — the case for polling over streaming

**Polling, not SSE/WebSocket.** The shared Dio instance carries a cookie
jar, a refresh-on-401 retry, and a `TalkerDioLogger` interceptor that all
assume request/response semantics. An SSE stream would need
`ResponseType.stream`, manual line framing, and would bypass the 401
retry entirely — a second transport path, which breaks the "one client"
rule this codebase already follows.

Mechanics, all inside `caseTimelineProvider` (§5.4):

- **Adaptive interval.** ~2s while the case status says the agent is
  working (`intake`/`planning`, or an in-flight `advanceCaseController`
  call), ~10s otherwise. The stream returns at terminal case states, so a
  completed case costs zero further requests. `autoDispose` stops
  polling the instant the screen is popped.
- **Delta fetches.** Each tick sends `sinceSeq=<cursor>`; the server
  returns only new actions and the client prepends them. A long-running
  case's timeline never re-downloads what it already has.
- **`POST /advance` doesn't block the UI thread** — fire it via
  `advanceCaseControllerProvider`, let the timeline poll pick up what it
  did as it happens, and use the button's own loading state (not a
  full-screen spinner) to show it's in flight. When it resolves, force
  one immediate timeline poll rather than waiting for the next interval
  tick, so the UI doesn't feel laggy right when the loop finishes.

**While the agent is thinking:**
- `AgentStatusBanner` pins to the top of case detail while
  `status.isAgentWorking`: pulsing dots, a generic "SewaSathi is working
  on your case" line (there is no per-step label from the backend —
  don't invent one), "updated Ns ago".
- The timeline's head, while an `advanceCaseController` call is in
  flight, shows a distinct in-progress node — hollow circle, dashed rail
  segment above it — so the next entry visually reads as "being written."
- Existing nodes stay fully interactive. Only the very first load shows
  `CircularProgressIndicator.adaptive`; every poll after that is silent,
  with only the delta animating in (`AnimatedSize` on the list head).
- **Poll failure doesn't clear the screen.** `StreamProvider` surfaces
  `AsyncError` with the previous value retained; show a small dismissible
  "Reconnecting…" strip under the app bar and keep retrying at the slow
  interval. Losing the timeline on one flaky request is the worst
  possible failure mode for a demo.
- Accessibility: the banner is `Semantics(liveRegion: true)`; when
  `MediaQuery.disableAnimationsOf(context)` is true, the pulse becomes a
  static indeterminate bar.

`ponytail:` note worth leaving on the provider: fixed 2s/10s intervals
with no backoff and no jitter. Fine for one client hitting a simulated
backend — add exponential backoff on consecutive errors if this ever
faces real concurrent load.

## 9. Tests

`test/` currently holds only `widget_test.dart` (flat, no subdirs).
Mirroring the `lib/features/...` shape:

```
test/widget_test.dart                                   UNCHANGED — verified no references to deleted features.
test/features/cases/case_progress_test.dart              Pure: computeCaseProgress over a 4-5 service plan — fraction, nextService skips terminal applications, total==0 doesn't divide by zero.
test/features/cases/case_model_test.dart                 CitizenCase/AgentAction fromJson over a realistic envelope payload; unknown enum strings and null fields fall back instead of throwing.
test/features/cases/case_timeline_polling_test.dart      The one with real logic. Fake CaseRepository via ProviderContainer override; asserts (a) sinceSeq cursor advances from nextSeq, (b) actions accumulate newest-first without duplicates, (c) the generator STOPS at a terminal case status.
test/features/cases/agent_timeline_test.dart              Widget test: renders several actions, expands one reasoning body. Runs at tester.view.physicalSize compact (400x800) and expanded (1000x800), plus once wrapped in MediaQuery(textScaler: TextScaler.linear(2.0)) asserting no overflow. addTearDown(tester.view.reset).
test/features/documents/missing_requirements_test.dart   Pure: a mandatory requirement with a rejected verdict still counts as missing; an optional one never does.
```

Five new files. No mocking package — hand-rolled fakes implementing the
abstract repositories, exactly like the existing `_FakeAuthRepository` in
`widget_test.dart`. `case_timeline_polling_test.dart` uses
`fakeAsync`/`tester.pump(Duration)` to skip the real multi-second waits.

Not writing: golden tests (no golden infrastructure exists in `.github/`
— a separate task) or integration tests (`integration_test` isn't in
`pubspec.yaml`).

## 10. Migration order

Each phase ends with `flutter analyze` clean before moving on.

| # | Phase | Notes |
|---|---|---|
| 0 | Baseline: `flutter analyze`, record current state | Confirm 0 issues before touching anything |
| 1 | **Deletions** (§3) — 54 + 3 files, `providers.dart`, `app_routes.dart`, `route_paths.dart`, `api_client.dart`, `app.dart` | Coordinate timing with backend phase 1 — old routes 404 the moment that ships |
| 2 | `pubspec.yaml` — remove the five dead packages, add `image_picker` | Own commit, separate from feature work — Gradle/Podfile churn from removing Firebase packages should be independently bisectable |
| 3 | **Domain layer** — entities for `cases` and `documents` (§4.1, §4.2) | Pure Dart, no Dio/Flutter imports |
| 4 | **Data layer** — DTOs + repository impls (§6 endpoint table) | Match the backend's actual snake_case enum values — write the mapping tables explicitly |
| 5 | **DI wiring** (§7.1) | `flutter analyze` proves nothing dangling |
| 6 | **Responsive foundation** (§5.0) | Two files, no dependents yet |
| 7 | **Providers** (§5.4) | Timeline polling logic first — it's the one worth testing in isolation before screens depend on it |
| 8 | **Screens + widgets** (§5.1, §5.2), routing (§7.3) | `AgentTimeline` and `CaseDetailScreen` last — they depend on everything above |
| 9 | **Tests** (§9) | |
| 10 | **`docs/coordination.md`** update, mirrored from the backend's phase 11 | Coordinate timing — do this together, not independently |

### Lockstep with the backend

1. Phase 1 here and phase 1 in `socketTest` must ship together — the
   moment the backend deletes `/api/finance`, `/api/todos`, `/api/sleep`,
   this client's repositories calling them break. Delete both sides in
   the same change.
2. The response-envelope shape (named keys, not bare arrays) and the
   `snake_case` enum casing are the two places an earlier,
   independently-planned draft of this document guessed wrong. Both are
   corrected here — if the backend contract changes again, re-verify
   against `socketTest/docs/sewasathi-implementation-plan.md` §8 before
   writing repository code.
3. `docs/coordination.md`'s existing open issues about Flutter
   bearer/CSRF handling should be resolved (or reconfirmed resolved) as
   part of phase 0/1 here — they're a prerequisite for any of this
   working end to end, not a nice-to-have.

## 11. Risks, guesses, open questions

1. **`image_picker` is the one new dependency.** Needs
   `NSCameraUsageDescription` + `NSPhotoLibraryUsageDescription` in
   `ios/Runner/Info.plist`, an iOS privacy-manifest entry, and Android
   13+ `READ_MEDIA_IMAGES`. It does not handle PDFs — a citizenship
   certificate scan as PDF won't be pickable through it. Add
   `file_picker` only if a PDF-only document type turns out to matter for
   the flagship journey's requirement list; don't add it speculatively.
2. **`/advance`'s per-request timeout override (90s)** assumes the real
   model adapter, once wired server-side, responds within that window.
   If it doesn't, this needs revisiting together with the backend side —
   it is not solvable from the client alone.
3. **Polling cadence (2s/10s) is a fixed guess**, not tuned against
   real device/network conditions. Fine for a demo; watch battery/data
   use if this becomes a real deployment target.
4. **Web platform note:** `image_picker`'s multipart path relies on
   `MultipartFile.fromFile(path)`, which needs `dart:io` and won't work
   on Flutter Web. If web is part of the demo, document upload needs
   `MultipartFile.fromBytes` there instead — simplest fix is to just not
   demo document upload on web.
5. **Open question:** should the officer console ever get a screen in
   this app? Currently explicitly out of scope (§6) — it uses a
   different auth mechanism entirely (`X-Officer-Key`) and would need a
   `role` field on `User` that doesn't exist yet. Revisit only if asked.
6. **Open question:** the escalation flow currently has no citizen-facing
   messaging surface beyond the timeline showing an `officerResolved`
   event with its `reasoning`. If a real back-and-forth with an officer
   is wanted later, that's a materially different feature (a message
   thread) — flag it rather than half-build it now.
