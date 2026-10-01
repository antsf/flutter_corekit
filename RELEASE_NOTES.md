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
