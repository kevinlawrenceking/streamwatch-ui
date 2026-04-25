# StreamWatch Legacy UI — Deploy Runbook

Reference for the hardened deploy pipeline introduced in WO-073/LSW-013.
Production URL: https://dpoqt8yacebtf.cloudfront.net

## 1. What `deploy-frontend.sh` now does automatically

- **Pre-flight aborts** on tracked-dirty working tree or `HEAD != origin/master`
  (override: `--force-local`, which warns but proceeds).
- **Interactive confirmation** of the commit SHA before deploy
  (override: `-y` / `--yes` for non-interactive runs).
- **Build SHA embedded** via `flutter build web --release --dart-define=GIT_SHA=<short hash>`.
- **SW auto-activation verified** post-build (read-only assertion against
  `build/web/flutter_service_worker.js`):
  - Install handler must call `self.skipWaiting()` (count >= 1) so a new SW
    activates immediately rather than parking in `waiting` state.
  - Activate handler must call ONE of `self.clients.claim()` (legacy
    Flutter pattern) OR `self.registration.unregister()` (modern Flutter
    3.10+ kill-switch pattern). Either guarantees existing pages see new
    builds without manual cache clear. Hard-fails the deploy if neither
    is present.
- **`main.dart.js` is `Cache-Control: no-cache, no-store, must-revalidate`**
  alongside the existing four files (index.html, flutter_service_worker.js,
  flutter_bootstrap.js, version.json). The whole-app bundle was previously
  served with no Cache-Control header, which compounded with the SW cache to
  produce stale-app symptoms.
- **CloudFront `/*` invalidation** after S3 sync.
- **ETag assertion** (5 x 10s retry) — local md5(main.dart.js) must match
  live ETag. Hard-fails the deploy if it doesn't.
- **Canary-string assertion** (5 x 10s retry) — default `"No scheduled jobs yet"`,
  override via `--assert-string "<your string>"`. Hard-fails if missing.
- **Deploy tag**: `deploy-YYYYMMDD-HHMMSS` (UTC, seconds-resolution to avoid
  same-minute collisions) created and pushed to origin.
- **`deploy.log` append**: tab-separated `<ISO8601>\t<short sha>\t<etag>\t<cf dist id>`.
  Covered by the existing `*.log` pattern in `.gitignore`.
- **Footer build SHA** rendered in `_LogoutFooter` (every non-login view) for
  visual confirmation that the loaded bundle matches the deployed commit.

## 2. When a user still sees stale content — manual cache-kill steps

The structural fixes above prevent the recurring staleness pattern. If a
specific user still reports stale content, walk them through one of these:

### Chrome
1. Open the page, press `F12` (DevTools).
2. Application tab -> Service Workers -> find the streamwatch entry.
3. Click "Unregister".
4. Press `Ctrl+Shift+R` (or `Cmd+Shift+R` on macOS) to hard-reload.

### Edge
Same path as Chrome (DevTools layout is identical).

### Safari
1. Develop menu -> Empty Caches.
2. Close all tabs/windows of the origin.
3. Reopen the page.

(Safari doesn't expose the SW registration in the same UI — closing all
windows of the origin is what frees the waiting SW.)

## 3. PWA unpin

If a user installed the site as a PWA (Chrome/Edge "Install app" prompt):
1. Inside the PWA window, three-dot menu -> Uninstall.
2. Reopen the site fresh in a normal browser tab — that re-fetches everything.

## 4. Nuclear option

Application tab -> Storage -> Clear site data. This wipes everything
(cookies, localStorage, IndexedDB, SW registration), so the user will need
to re-authenticate. Use as a last resort.

## 5. How to verify the live build matches your local build

Two independent cross-checks:

- **Footer SHA**: open the app and look at the bottom of the nav rail. The
  text reads `build <sha>`. Compare to your local
  `git rev-parse --short HEAD`.
- **ETag**: `curl -sI https://dpoqt8yacebtf.cloudfront.net/main.dart.js`
  and grep ETag. Compare to local `md5sum build/web/main.dart.js`.
  They will match (the CloudFront ETag for an S3 object is the md5 of the
  uploaded bytes for objects under 5 GB).

## 6. Root-cause reference

Recurring staleness was traced to three structural causes (all fixed as of
WO-073/LSW-013):

1. **Flutter SW waiting-state activation window** — Flutter's SW historically
   installed into `waiting` state and only activated when every tab/window
   for the origin closed; hard-refresh did not help (flutter/flutter#96144).
   Modern Flutter (3.10+) ships a kill-switch SW that calls
   `self.skipWaiting()` on install and `self.registration.unregister()` on
   activate, then navigates open clients to refetch — this fully resolves
   the activation window. WO-073 verifies the SW retains these properties
   on every deploy and hard-fails if Flutter ever regresses.
2. **`main.dart.js` had no Cache-Control header** — the previous deploy
   script tagged 4 files no-cache but missed the 3.6 MB main bundle.
   CloudFront default TTL applied, layered on top of the SW cache.
3. **Deploy hygiene was lossy** — silent stale deploys, no visible
   confirmation of what was live, no post-deploy verification, no tag
   history, occasional `git reset --hard` events that dropped commits
   (`git reflog` evidence). Fixed by the pre/post-flight blocks, deploy
   tags, deploy.log, and the in-UI SHA.

For the diagnostic write-up that produced this WO, see the WO-073 brief.
