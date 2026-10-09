# Accessible reusable CoreKit widgets

## Approved scope

User approved extending CoreKit beyond its existing Material modal helpers with true package-owned reusable widgets and integrating the UI into OMS. Build generic modal, button, input/password, feedback (notice/snackbar), state, icon action, choices and status badge families. Names are new APIs, not claims of pre-existing exports. Preserve the public extension APIs and all unrelated WIP. No commit/push/release/device install authorized.

## Design contract

Follow ThemeData/ColorScheme/TextTheme. No OMS brand assets, domain validators, credentials, networking, Riverpod or new dependencies in these widgets. Support text scale 1/1.5/2/3 without clamping or essential text ellipsis; minimum 48 touch targets, minimum 50 controls at normal scale, controls grow with text. Keyboard-safe scrollable modal surfaces; actual package-owned composition even though Flutter Material may be used internally. Feature source does not call raw Material modal APIs.

Button loading matches supplied HubButton.kt: centered 16px circular progress, strokeWidth 1, no visible label or leading/trailing icons. Keep normal/loading geometry stable, disable duplicate actions, expose original label + loading semantics. Respect reduced motion. Use corresponding semantic foreground/surface colors rather than blindly copying low-contrast alpha states from Kotlin. User requested spinner behavior, not Kotlin fixed heights that clip large Flutter fonts.

## Implemented public API and ownership

- CoreButton / CoreButtonVariant: primary, secondary, danger, tonalPrimary, tonalDanger, outlined, text. Label, onPressed, isLoading, enabled, optional Widget leadingIcon/trailingIcon, pill, fullWidth, minHeight; no async business state owned.
- CoreTextField: same caller-owned controller/focus/validator/saved/change/submission/error/helper/autofill/actions/formatters as OMS AppTextField; optional semanticsLabel, no custom business validation. CorePasswordField composes it with show/hide and safe input flags (can be controlled or local UI state).
- CoreIconButton: Widget icon, tooltip, onPressed, enabled, optional badge; minimum48.
- CoreChoiceGroup<T> / CoreChoice<T>: typed values and caller-owned selection. CoreChoicePresentation.list uses radio/checkbox rows; chips uses ChoiceChip for single selection and FilterChip for multiple selection. Chips allow clearing the selected value. Callback sets are immutable and caller collections are never mutated. CoreCheckboxOption is available independently. No fetching.
- CoreStatusBadge: label, semantic tone, optional icon, wraps; purely presentation.
- CoreDialog and CoreBottomSheet: title/description/content, optional actions/footer, close/cancel policy, scroll/safearea/keyboard, max width, reduced motion; generic typed show returns result. Static show must use corekit public modal APIs, not alter legacy callers unexpectedly.
- CoreNotice, CoreSnackbar: generic presentation/body with title/description/semantic tone/icon/loading/onTap/onClose; queue/route integration remains OMS Riverpod service. CoreSnackbar package widget can own entry/exit motion if explicit state API; no service global.
- CoreStateView: loading/empty/error presentation with caller callbacks and optional icon; no domain state inference.

## Plan / tasks

1. Fresh fetched origin/main for CoreKit, preserve existing analysis_options.yaml and REVIEW_FIX_HANDOFF.md; no worktree. OMS remains feature branch based on dev. Package scope explicitly authorized.
2. Test-first vertical slices. Parallel ownership: controls/forms; modal surfaces; parent feedback/integration/exports/documentation.
3. Preserve existing app wrapper APIs while forwarding to CoreKit. Use local untracked pubspec_overrides.yaml to exercise unpublished package, not a fake remote pin. Remote pin migration remains pending publication approval.
4. Run package tests/analyzer, consumer OMS tests/analyzer, representative rendered evidence and independent review. Do not present unverified intermediate sources as complete.

## Historical six-widget integration checkpoint — 2026-10-09

- CoreButton, CoreDialog, CoreBottomSheet, CoreNotice, CoreSnackbar and CoreStateView are exported and locally consumed by OMS using an ignored dependency override.
- Their scoped regression has **142 successful tests** and a clean scoped analyzer. Full-package verification remains pending the remaining controls.
- OMS uses the actual CoreBottomSheet surface for recovery and filter sheets, not a helper rename. Current consumer full suite: **538 passed, zero skipped**; consumer analyzer clean.
- Preserve the normal/loading button footprint with hidden content that still participates in layout; expose only spinner visually, keeping original-label/busy semantics. Reduced motion disables ticker and uses static progress.
- Root notification surfaces can sit above Navigator, so tooltip availability must not be assumed: provide a semantics label when no Overlay ancestor exists. Exactly one layer owns the live-region announcement.
- Remaining control adapters and independent review are not accepted yet. No package publication or device installation has occurred; a local lock/path dependency is not a publishable remote pin.

## Completed source verification — 2026-10-09

- All approved widget families are implemented and exported. OMS button/input/password/icon/checkbox/badge/notice/snackbar wrappers delegate to package-owned presentation; dialog/state widgets are available without creating unnecessary app usages.
- Chips tests cover single/multiple selection, scales 1/1.5/2/3 at width 240, minimum 48 targets, disabled options/groups, replacement/removal, immutable callback sets and caller-owned collection preservation.
- Native hints use hintText/hintMaxLines rather than InputDecoration.hint, which is absent in the official Flutter 3.27 source. A copy-length-derived line bound avoids inheriting the input's single-line limit. RenderParagraph.didExceedMaxLines checks verify no actual hint truncation.
- Password forwarding preserves initialValue, prefix, keyboard type, formatters, readOnly, autofill and semanticsLabel. Suggestions/autocorrect remain disabled even when revealed, and caller-owned controllers/focus remain caller-owned.
- Full package suite: **655 passed, zero skipped**. Consumer OMS: **545 passed, zero skipped**. Both analyzers clean. Executed toolchain: Flutter 3.47.1 / Dart 3.13.1; no full Flutter 3.27 runtime/dependency matrix was executed.
- Independent source review passed with no blocking security, logic or implementation-scope findings. Prior editable-label and chips findings are closed. One non-blocking suggestion is additional rendered-paragraph assertions for chip labels.
- Device testing is paused at the user's request. No new APK/install or device-setting changes. Publication approval is for a source branch/PR and immutable consumer pin, not merge, tag, pub.dev release or repository-settings changes.
- Unrelated analysis_options.yaml and REVIEW_FIX_HANDOFF.md WIP are excluded from the publication commit.
