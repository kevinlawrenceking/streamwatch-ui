#!/usr/bin/env bash
# Deploy StreamWatch Flutter frontend to S3 + CloudFront.
#
# Usage:
#   ./scripts/deploy-frontend.sh              # build + deploy
#   ./scripts/deploy-frontend.sh --skip-build # deploy existing build/web
#
# Environment overrides (or export before running):
#   SW_API_BASE_URL   - API URL baked into build (default: production API Gateway)
#   SW_S3_BUCKET      - S3 bucket for web assets
#   SW_CF_DIST_ID     - CloudFront distribution ID
#   SW_REGION         - AWS region (default: us-east-1)

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults — sourced from CLAUDE.md authoritative values
# ---------------------------------------------------------------------------
API_BASE_URL="${SW_API_BASE_URL:-https://u0o3w9ciwh.execute-api.us-east-1.amazonaws.com}"
S3_BUCKET="${SW_S3_BUCKET:-streamwatch-frontend-dev-259270188737}"
CF_DIST_ID="${SW_CF_DIST_ID:-EE0PAJB58A75G}"
REGION="${SW_REGION:-us-east-1}"
SKIP_BUILD=false

for arg in "$@"; do
  case "$arg" in
    --skip-build) SKIP_BUILD=true ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UI_ROOT="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$UI_ROOT/build/web"

echo "========================================"
echo " StreamWatch Frontend Deployment"
echo "========================================"
echo "API URL:    $API_BASE_URL"
echo "S3 Bucket:  $S3_BUCKET"
echo "CF Dist:    $CF_DIST_ID"
echo "Region:     $REGION"
echo "Skip Build: $SKIP_BUILD"
echo ""

# Step 1: Verify AWS credentials
echo "[1/4] Verifying AWS credentials..."
aws sts get-caller-identity --region "$REGION" > /dev/null
echo "  OK"

# Step 2: Build
if [ "$SKIP_BUILD" = false ]; then
  echo ""
  echo "[2/4] Building Flutter web app..."
  cd "$UI_ROOT"
  flutter build web --release \
    --dart-define="API_BASE_URL=$API_BASE_URL" \
    --dart-define=ENV=production
  echo "  Build complete: $BUILD_DIR"
else
  echo ""
  echo "[2/4] Skipping build (using existing build/web)"
  if [ ! -d "$BUILD_DIR" ]; then
    echo "ERROR: $BUILD_DIR not found. Run without --skip-build." >&2
    exit 1
  fi
fi

# Step 3: Sync to S3
echo ""
echo "[3/4] Syncing to s3://$S3_BUCKET ..."
aws s3 sync "$BUILD_DIR" "s3://$S3_BUCKET" --delete --region "$REGION"

# Set no-cache headers for mutable files
for f in index.html flutter_service_worker.js flutter_bootstrap.js version.json; do
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

echo ""
echo "========================================"
echo " Deployment Complete!"
echo "========================================"
echo "URL: https://dpoqt8yacebtf.cloudfront.net"
echo ""
echo "Note: CloudFront propagation may take 1-5 minutes."
