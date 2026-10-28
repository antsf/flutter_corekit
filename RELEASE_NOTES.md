# flutter_corekit unreleased source feature

Source preparation date: 2026-10-28. Branch: `feat/bottom-sheet-inline-header`.
This is source-delivery documentation for the accessible-widget follow-ups; the
detailed list lives in `CHANGELOG.md` (Unreleased section). The prepared
`3.1.1` release notes below still describe the last versioned checkpoint.

## Main changes

- CoreBottomSheet matches the reference sheet composition: a theme drag-handle
  pill atop the body scroll column with the one-row title/close header over it.
- Dialog and sheet surfaces share internal `ModalSurfaceBody` /
  `ModalSurfaceCloseButton` parts; the scrolling body column and close button
  behavior change in one place instead of twice.
- Close control is a 48px `CoreIconButton`; a hard size floor keeps the touch
  target even in squeezed landscape headers.
- `CoreTextFieldVariant.textarea` for multiline input and hint wrapping; plain
  fields keep a one-line ellipsized hint (see
  `doc/features/text-field-variants.md`).
- CoreButton/CoreTextField colors and styles resolve through the `context.*`
  theme-role extensions.

## Verification and limits

Full package suite 663 passed, zero skipped; analyzer clean (Flutter
3.47.1 / Dart 3.13.1 toolchain as documented). No consumer re-run was executed
for this branch. Device testing remains paused per standing user instruction.

## Publication boundary

Commit + branch push + PR only. No package version bump, tag, GitHub Release
or pub.dev publication is created by this step; consumers pin the full commit
SHA from the PR until a merge/tag is explicitly approved.

---

# flutter_corekit 3.1.1

Release preparation date: 2026-10-01. This is a patch release of the existing
3.1 API, focused on session isolation, lifecycle correctness and private-data
logging. The detailed change list is in `CHANGELOG.md`.

## Main changes

- GET cache isolation for managed sessions and request-specific Authorization.
- Session captured before Dio queues interceptors; stale requests, refreshes and
  retries cannot cross logout/account-switch boundaries.
- Refresh failure recovery and bounded retry for delayed same-session 401s.
- Conservative cache bypass for custom/mutable request-processing contexts.
- Initialization concurrency/reset fixes, safe error mapping, route substitution,
  phone boundaries, debounce cleanup, absent-item deletion and validator policy.
- Metadata-only network diagnostics and redacted password/OTP diagnostics.

## Upgrade behavior

Handle cancellation failures for requests invalidated by an identity change.
Switch identity using the client's auth-management API. Route parameter values
`.` and `..` are rejected. Cache bypass may cause extra network requests for
custom transformers/interceptors. Logs deliberately omit raw URLs and private
error/payload text; applications should not depend on that diagnostic content.

## GitHub consumption before merge

```yaml
dependencies:
  flutter_corekit:
    git:
      url: https://github.com/antsf/flutter_corekit.git
      ref: fix/independent-review-20260930
```

Replace the branch with the full reviewed commit SHA from the PR for immutable
application dependencies, and commit your app's `pubspec.lock`. OMS/PH apps
using `antsf_flutter_starter` get this corekit revision through its pinned Git
dependency; no local path dependency or override is required.

## Verification and limits

The pre-release source checkpoint passed 484 unit/widget tests, analyzer,
formatting and whitespace checks, plus independent source review and focused
session-race re-review. Native Android/iOS/device plugin behavior is not covered
by those checks. Notifications and save_to_dir are not part of this release.

## Publication boundary

The current delivery is commit + branch push + PR to `main`, without automatic
merge. Version `3.1.1` is prepared in source; no `v3.1.1` tag, GitHub Release or
pub.dev publication is created by this PR-opening step. After approved merge,
the existing tag-triggered release workflow verifies and creates the GitHub
Release from the matching CHANGELOG section. Publishing to pub.dev remains a
separate, explicitly approved action.
