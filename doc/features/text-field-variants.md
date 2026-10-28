# CoreTextField line policy

## Approved contract

The user approved secondary Dashboard hint styling through `context.bodyMediumSecondary`, and clarified that multiline input/hints are exclusive to the textarea variant. Implement in CoreKit source, not in Pub cache. Keep labels, helper and validation errors readable; this line policy applies to the editable field body and its hint, not supporting messages.

- T1: Ordinary CoreTextField and CorePasswordField have one input line and one native hint line. Long hints use ellipsis, including at large text scale.
- T2: Explicit `CoreTextFieldVariant.textarea` permits multiline input and hint. Default textarea is unbounded; a positive maxLines bounds both input and hint, with ellipsis preventing bounded hints from painting past their lines. Textarea defaults to multiline keyboard/newline action. Obscured textarea and multiline options on an ordinary field are rejected; ordinary fields remain one line in release as well.
- T3: Dashboard hint inherits secondary body-medium style via the public TextThemeExtensions API. Existing hint strings, search/focus/clear/filter callbacks, field ownership, and layout remain intact.
- T4: Preserve controller/focus/form/autofill/formatting/validation behavior and large-font helper/error wrapping. Expose the variant through the OMS AppTextField adapter.

## Branch / dependency boundaries

CoreKit WIP was explicitly checkpointed locally as `06c4cc73df2b5a25da2444fabea3c2189ca7eb42` on `feat/accessible-core-widgets`, preserving only analysis_options.yaml and REVIEW_FIX_HANDOFF.md. Feature branch `feat/text-field-single-line-textarea` starts at fetched origin/main `3ec1a75`. No feature commit, push, merge or release is authorized.

OMS stays on its existing fix branch with all unrelated WIP intact. Use an ignored local pubspec_overrides.yaml to exercise the unpublished source. Preserve declared Git pins; disclose the local path/lock resolution. Never edit the cached pinned package. Publication and replacing the consumer's immutable remote pin require separate authorization.

## Plan / tasks

1. Reproduce ordinary long-hint geometry violating one-line policy; update the test oracle to the new user decision.
2. Implement typed text/textarea variants and regression coverage at normal/large scale, including invalid combinations and password composition.
3. Forward the variant in the consumer adapter, apply secondary hint style only to Dashboard, and test rendered color/one-line ellipsis and textarea forwarding.
4. Run package suite/analyzer, risk-based consumer tests/analyzer, format/diff checks and independent read-only review. Record any inherited/newer unrelated WIP failures separately; do not weaken tests or edit unrelated WIP to manufacture a clean verdict.

## Compatibility / migration

Existing default fields remain one-line inputs but their long hints now ellipsize by the latest user decision. Multiline callers must opt into `CoreTextFieldVariant.textarea`; merely setting maxLines is no longer sufficient. Supporting helper/error text continues to wrap. Earlier multiline-hint accessibility expectations are superseded for ordinary fields, retained for textarea and supporting messages.

## Verification

- RED ordinary hints at scales 1/3: expected hintMaxLines 1, actual 66, exit 1. Source was changed only after this reproduction.
- RED Dashboard rendered hint color at scales 1/3 before its style change: actual color differed from context.bodyMediumSecondary, exit 1. Textarea adapter test already passed.
- CoreKit `flutter test --no-pub --machine`: **662 passed, zero failures/errors/skips**, exit 0. `flutter analyze --no-pub`: no issues, exit 0.
- OMS risk-based selection: **171 passed, zero failures/errors/skips**, exit 0. Includes Dashboard rendered color/ellipsis, focus/modal lifecycle, shared controls, password adapter, and the auth accessibility matrix. Its test oracle now distinguishes ordinary one-line hints from explicit textarea and still prohibits truncating other labels/helpers/errors.
- OMS scoped analyzer of the modified adapter/toolbar/tests: no issues, exit 0. Whole-repository analyzer still reports one pre-existing `unnecessary_import` info in unrelated auth_footer.dart WIP; it was not modified for this task. No whole-OMS-suite pass is claimed.
- `git diff --check`: exit 0 for both repos. Scoped formatter checks: 0 changed, exit 0 in both repos. Independent read-only review is pending finalization.
- Resolved OMS flutter_corekit root is `file:///C:/src/flutter_dir/my_packages/flutter_corekit`. The ignored pubspec_overrides.yaml and resulting local-path pubspec.lock diff are development-only; declared pubspec.yaml Git refs remain unchanged. Do not commit the local-path lock resolution for publication.
- Evidence logs under `C:/Users/atgpg/AppData/Local/hermes/cache/scratch/`: `corekit-standard-hint-red-20261014.log`, `oms-toolbar-hint-red-20261014.log`, `corekit-field-variants-full-20261014.jsonl`, `corekit-field-variants-analyze-20261014.log`, `oms-field-variants-selected-20261014.jsonl`, `oms-field-variants-scoped-analyze-20261014.log`, `field-variants-verification-summary-20261014.json`.

Only the explicitly approved WIP checkpoint was committed; all implementation remains uncommitted. No push, merge, publication, APK build or device QA occurred.
