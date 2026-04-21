#!/usr/bin/env bash
# Deploy StreamWatch Flutter frontend to S3 + CloudFront.
#
# Usage:
#   ./scripts/deploy-frontend.sh                       # build + deploy (interactive)
#   ./scripts/deploy-frontend.sh -y                    # non-interactive
#   ./scripts/deploy-frontend.sh --use-existing-build  # deploy existing build/web
#   ./scripts/deploy-frontend.sh --force-local         # bypass pre-flight guards
#   ./scripts/deploy-frontend.sh --assert-string "Custom canary"
#
# Environment overrides (or export before running):
#   SW_API_BASE_URL    - API URL baked into build (default: production API Gateway)
#   SW_S3_BUCKET       - S3 bucket for web assets
#   SW_CF_DIST_ID      - CloudFront distribution ID
#   SW_REGION          - AWS region (default: us-east-1)
#   SW_ASSERT_STRING   - Post-flight canary string (default: "No scheduled jobs yet")

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
API_BASE_URL="${SW_API_BASE_URL:-https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com}"
S3_BUCKET="${SW_S3_BUCKET:-streamwatch-frontend-dev-259270188737}"
CF_DIST_ID="${SW_CF_DIST_ID:-EE0PAJB58A75G}"
REGION="${SW_REGION:-us-east-1}"
ASSERT_STRING="${SW_ASSERT_STRING:-No scheduled jobs yet}"
CF_DOMAIN="https://dpoqt8yacebtf.cloudfront.net"

USE_EXISTING_BUILD=false
FORCE_LOCAL=false
YES=false

# ---------------------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --use-existing-build) USE_EXISTING_BUILD=true; shift ;;
    --force-local)        FORCE_LOCAL=true; shift ;;
    -y|--yes)             YES=true; shift ;;
    --assert-string)      ASSERT_STRING="$2"; shift 2 ;;
    --assert-string=*)    ASSERT_STRING="${1#--assert-string=}"; shift ;;
    -h|--help)
      cat <<'USAGE'
Usage: ./scripts/deploy-frontend.sh [flags]
  --use-existing-build   Deploy existing build/web (skip flutter build)
  --force-local          Bypass pre-flight dirty-tree / HEAD-vs-origin aborts (warns)
  -y, --yes              Skip interactive confirmation
  --assert-string STR    Post-flight canary string (default: "No scheduled jobs yet")
  -h, --help             Show this help
USAGE
      exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$UI_ROOT/build/web"

# ---------------------------------------------------------------------------
# Pre-flight: tracked-dirty tree + HEAD-vs-origin guards + confirmation
# ---------------------------------------------------------------------------
commit_sha=$(git -C "$UI_ROOT" rev-parse --short HEAD)
commit_full=$(git -C "$UI_ROOT" rev-parse HEAD)
remote_head=$(git -C "$UI_ROOT" rev-parse origin/master 2>/dev/null || echo "")

echo "[pre-flight] commit:        $commit_sha ($commit_full)"
echo "[pre-flight] origin/master: ${remote_head:-<unresolved>}"

# Tracked-dirty check — untracked files do NOT fail pre-flight
if ! git -C "$UI_ROOT" diff-index --quiet HEAD --; then
  if [ "$FORCE_LOCAL" = false ]; then
    echo "ERROR: working tree has tracked modifications:" >&2
    git -C "$UI_ROOT" diff-index --name-status HEAD -- >&2
    echo "  Commit, stash, or rerun with --force-local." >&2
    exit 1
  else
    echo "WARNING: --force-local -- deploying with tracked-dirty tree"
  fi
fi

# HEAD vs origin/master
if [ -n "$remote_head" ] && [ "$commit_full" != "$remote_head" ]; then
  if [ "$FORCE_LOCAL" = false ]; then
    echo "ERROR: HEAD ($commit_full) != origin/master ($remote_head)." >&2
    echo "  Push or rerun with --force-local." >&2
    exit 1
  else
    echo "WARNING: --force-local -- deploying a commit that is not on origin/master"
  fi
fi

# Interactive confirmation (unless -y / --yes)
if [ "$YES" = false ]; then
  read -r -p "Deploy $commit_sha to $CF_DOMAIN? [y/N] " ans || ans=""
  case "$ans" in
    y|Y) ;;
    *) echo "  Aborted by user."; exit 1 ;;
  esac
fi

echo "========================================"
echo " StreamWatch Frontend Deployment"
echo "========================================"
echo "Commit:     $commit_sha"
echo "API URL:    $API_BASE_URL"
echo "S3 Bucket:  $S3_BUCKET"
echo "CF Dist:    $CF_DIST_ID"
echo "Region:     $REGION"
echo "Use Build:  $USE_EXISTING_BUILD"
echo "Canary:     \"$ASSERT_STRING\""
echo ""

# Step 1: Verify AWS credentials
echo "[1/4] Verifying AWS credentials..."
aws sts get-caller-identity --region "$REGION" > /dev/null
echo "  OK"

# Step 2: Build
if [ "$USE_EXISTING_BUILD" = false ]; then
  echo ""
  echo "[2/4] Building Flutter web app..."
  cd "$UI_ROOT"
  flutter build web --release \
    --dart-define="API_BASE_URL=$API_BASE_URL" \
    --dart-define=ENV=production \
    --dart-define=GIT_SHA=$commit_sha
  echo "  Build complete: $BUILD_DIR"
else
  echo ""
  echo "[2/4] Skipping build (using existing build/web)"
  if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: $BUILD_DIR not found. Run without --use-existing-build." >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------
# SW auto-activation patch (idempotent)
#   - install handler: ensure self.skipWaiting() follows the anchor
#       (current Flutter template already includes this -- guard no-ops)
#   - activate handler: inject event.waitUntil(self.clients.claim()) as the
#     FIRST statement of the handler body, augmenting existing in-try-block
#     claims so claim happens even if the inner async cache work throws.
# ---------------------------------------------------------------------------
SW="$BUILD_DIR/flutter_service_worker.js"
if [ ! -f "$SW" ]; then
  echo "ERROR: $SW not found after build" >&2
  exit 1
fi

# Install handler patch (idempotent)
if ! grep -A1 'self\.addEventListener("install", (event) => {' "$SW" \
     | grep -q 'self\.skipWaiting();'; then
  if ! sed -i 's|self\.addEventListener("install", (event) => {|&\n  self.skipWaiting();|' "$SW" 2>/dev/null; then
    sed 's|self\.addEventListener("install", (event) => {|&\n  self.skipWaiting();|' "$SW" > "$SW.tmp" && mv "$SW.tmp" "$SW"
  fi
  echo "  SW install: injected self.skipWaiting()"
else
  echo "  SW install: self.skipWaiting() already present (no-op)"
fi

# Activate handler patch (idempotent on the exact injected literal)
if ! grep -qF 'event.waitUntil(self.clients.claim())' "$SW"; then
  if ! sed -i 's|self\.addEventListener("activate", function(event) {|&\n  event.waitUntil(self.clients.claim());|' "$SW" 2>/dev/null; then
    sed 's|self\.addEventListener("activate", function(event) {|&\n  event.waitUntil(self.clients.claim());|' "$SW" > "$SW.tmp" && mv "$SW.tmp" "$SW"
  fi
  echo "  SW activate: injected event.waitUntil(self.clients.claim())"
else
  echo "  SW activate: event.waitUntil(self.clients.claim()) already present (no-op)"
fi

# Step 3: Sync to S3
echo ""
echo "[3/4] Syncing to s3://$S3_BUCKET ..."
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" --delete --region "$REGION"

# Set no-cache headers for mutable files (now includes main.dart.js)
for f in index.html flutter_service_worker.js flutter_bootstrap.js version.json main.dart.js; do
  if [ -f "$BUILD_DIR/$f" ]; then
    content_type="application/octet-stream"
    case "$f" in
      *.html) content_type="text/html" ;;
      *.js)   content_type="application/javascript" ;;
      *.json) content_type="application/json" ;;
    esac
    aws s3 cp "$BUILD_DIR/$f" "s3://$S3_BUCKET/$f" \
      --cache-control "no-cache, no-store, must-revalidate" \
      --content-type "$content_type" \
      --region "$REGION" > /dev/null
    echo "  $f -> no-cache"
  fi
done
echo "  Sync complete."

# Step 4: Invalidate CloudFront
echo ""
echo "[4/4] Invalidating CloudFront cache..."
MSYS_NO_PATHCONV=1 aws cloudfront create-invalidation \
  --distribution-id "$CF_DIST_ID" \
  --paths "/*" \
  --region "$REGION" > /dev/null
echo "  Invalidation created."

# ---------------------------------------------------------------------------
# Post-flight: ETag + canary-string assertions, deploy tag, deploy.log append
# ---------------------------------------------------------------------------
echo ""
echo "[post-flight] Verifying live deploy..."
local_md5=$(md5sum "$BUILD_DIR/main.dart.js" | awk '{print $1}')
echo "  local main.dart.js md5: $local_md5"

ETAG_PASS=false
remote_etag=""
for i in 1 2 3 4 5; do
  remote_etag=$(curl -sI "$CF_DOMAIN/main.dart.js" \
                | awk -F'"' 'tolower($0) ~ /^etag:/ {print $2}' \
                | tr -d '\r')
  if [ "$remote_etag" = "$local_md5" ]; then
    ETAG_PASS=true; break
  fi
  echo "  attempt $i/5: remote=${remote_etag:-<none>} local=$local_md5 -- retry in 10s"
  sleep 10
done
if [ "$ETAG_PASS" = true ]; then
  echo "ETAG_ASSERT: PASS ($remote_etag)"
else
  echo "ETAG_ASSERT: FAIL (local=$local_md5 remote=$remote_etag)"
  exit 1
fi

STRING_PASS=false
for i in 1 2 3 4 5; do
  if curl -s "$CF_DOMAIN/main.dart.js" | grep -qF "$ASSERT_STRING"; then
    STRING_PASS=true; break
  fi
  echo "  attempt $i/5: canary not found -- retry in 10s"
  sleep 10
done
if [ "$STRING_PASS" = true ]; then
  echo "STRING_ASSERT: PASS (\"$ASSERT_STRING\")"
else
  echo "STRING_ASSERT: FAIL (missing: \"$ASSERT_STRING\")"
  exit 1
fi

# Deploy tag -- ISO with seconds to avoid same-minute collisions; skip if present
DEPLOY_TAG="deploy-$(date -u +%Y%m%d-%H%M%S)"
if git -C "$UI_ROOT" rev-parse "refs/tags/$DEPLOY_TAG" >/dev/null 2>&1; then
  echo "  Tag $DEPLOY_TAG already exists -- skipping create"
else
  git -C "$UI_ROOT" tag -a "$DEPLOY_TAG" -m "Deploy $commit_sha to $CF_DOMAIN"
  if git -C "$UI_ROOT" push origin "$DEPLOY_TAG"; then
    echo "  Tag $DEPLOY_TAG pushed to origin"
  else
    echo "  WARN: tag push failed -- tag is local only"
  fi
fi

# deploy.log append (ISO8601 \t commit_sha \t etag \t distribution_id)
DEPLOY_LOG="$UI_ROOT/deploy.log"
printf '%s\t%s\t%s\t%s\n' \
  "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  "$commit_sha" \
  "$local_md5" \
  "$CF_DIST_ID" \
  >> "$DEPLOY_LOG"
echo "  deploy.log appended ($DEPLOY_LOG)"

echo ""
echo "========================================"
echo " Deployment Complete!"
echo "========================================"
echo "URL:        $CF_DOMAIN"
echo "Commit:     $commit_sha"
echo "ETag:       $remote_etag"
echo "Tag:        $DEPLOY_TAG"
echo ""
