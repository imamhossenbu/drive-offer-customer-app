#!/usr/bin/env bash
# One-command release for Alokito Telecom customer + admin apps.
#
#   ./scripts/release.sh 1.1.1 "রিফান্ড সমস্যা ঠিক করা হয়েছে"
#   ./scripts/release.sh 1.1.1 "জরুরি আপডেট" --force        # force everyone to update
#   ./scripts/release.sh 1.1.0 "..." --skip-build            # reuse already-built APKs
#
# What it does:
#   1. bumps version+build in both apps' pubspec.yaml (build = previous + 1)
#   2. runs tests and builds split-per-ABI release APKs for both apps
#   3. creates GitHub Release v<version> on this repo with all APKs
#      (customer, admin, SMS listener; arm64 + v7a)
#   4. updates app-config.json (version, build, links, notes) so the
#      download pages and the in-app update screen pick up the new release
#   5. commits and pushes everything
#
# Requirements: flutter, gh (logged in), python3, git. Run from anywhere.
set -euo pipefail

VERSION="${1:-}"
NOTES="${2:-}"
shift $(( $# >= 2 ? 2 : $# )) || true
FORCE=false
SKIP_BUILD=false
for arg in "$@"; do
  case "$arg" in
    --force) FORCE=true ;;
    --skip-build) SKIP_BUILD=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ || -z "$NOTES" ]]; then
  echo "Usage: $0 <version e.g. 1.1.1> \"<release notes>\" [--force] [--skip-build]" >&2
  exit 1
fi

REPO="imamhossenbu/drive-offer-customer-app"
TAG="v$VERSION"
CUST="$(cd "$(dirname "$0")/.." && pwd)"
ROOT="$(cd "$CUST/.." && pwd)"
ADMIN="$ROOT/drive-offer-admin-app"
LISTENER_DIR="$ROOT/alokito-telecom-backend/public/downloads"
OUT="$ROOT/apks/release-$TAG"

step() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }
die() { printf '\n\033[1;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

step "Checking prerequisites"
command -v flutter >/dev/null || die "flutter not found"
command -v gh >/dev/null || die "gh not found"
gh auth status >/dev/null 2>&1 || die "run: gh auth login"
for d in "$CUST" "$ADMIN"; do
  [[ "$(git -C "$d" branch --show-current)" == "main" ]] || die "$d is not on main"
  git -C "$d" pull -q --ff-only origin main
  if [[ -n "$(git -C "$d" status --porcelain -- lib pubspec.yaml)" ]]; then
    die "$d has uncommitted code changes; commit them first"
  fi
done
gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1 && die "release $TAG already exists"

current_build() { grep -E '^version:' "$1/pubspec.yaml" | sed -E 's/.*\+([0-9]+).*/\1/'; }
current_version() { grep -E '^version:' "$1/pubspec.yaml" | sed -E 's/^version: *([0-9.]+).*/\1/'; }

if $SKIP_BUILD; then
  BUILD="$(current_build "$CUST")"
  for d in "$CUST" "$ADMIN"; do
    [[ "$(current_version "$d")" == "$VERSION" ]] || die "--skip-build: $d pubspec is not $VERSION"
    [[ "$(current_build "$d")" == "$BUILD" ]] || die "--skip-build: build numbers differ between apps"
  done
else
  B1="$(current_build "$CUST")"; B2="$(current_build "$ADMIN")"
  BUILD=$(( (B1 > B2 ? B1 : B2) + 1 ))
  step "Setting version $VERSION+$BUILD"
  for d in "$CUST" "$ADMIN"; do
    sed -i '' -E "s/^version: .*/version: $VERSION+$BUILD/" "$d/pubspec.yaml"
  done
  for d in "$CUST" "$ADMIN"; do
    step "Testing $(basename "$d")"
    (cd "$d" && flutter test)
    step "Building $(basename "$d")"
    (cd "$d" && flutter build apk --release --split-per-abi)
  done
fi

step "Collecting APKs in $OUT"
mkdir -p "$OUT"
APK_CUST="$CUST/build/app/outputs/flutter-apk"
APK_ADMIN="$ADMIN/build/app/outputs/flutter-apk"
cp "$APK_CUST/app-arm64-v8a-release.apk"    "$OUT/drive-offer-customer.apk"
cp "$APK_CUST/app-armeabi-v7a-release.apk"  "$OUT/drive-offer-customer-v7a.apk"
cp "$APK_ADMIN/app-arm64-v8a-release.apk"   "$OUT/drive-offer-admin.apk"
cp "$APK_ADMIN/app-armeabi-v7a-release.apk" "$OUT/drive-offer-admin-v7a.apk"
cp "$LISTENER_DIR/driver-sms-listener.apk"     "$OUT/driver-sms-listener.apk"
cp "$LISTENER_DIR/driver-sms-listener-v7a.apk" "$OUT/driver-sms-listener-v7a.apk"

# Make sure the APKs really are this version (catches stale build outputs).
AAPT="$(ls -d "$HOME"/Library/Android/sdk/build-tools/*/aapt2 2>/dev/null | tail -1 || true)"
if [[ -n "$AAPT" ]]; then
  for f in drive-offer-customer.apk drive-offer-admin.apk; do
    vn="$("$AAPT" dump badging "$OUT/$f" | grep -o "versionName='[^']*'" | head -1)"
    [[ "$vn" == "versionName='$VERSION'" ]] || die "$f is $vn, expected $VERSION (rebuild without --skip-build)"
  done
fi

step "Creating GitHub Release $TAG"
gh release create "$TAG" "$OUT"/*.apk --repo "$REPO" --title "আলোকিত টেলিকম $TAG" --notes "$NOTES"

step "Updating app-config.json"
python3 - "$CUST/app-config.json" "$VERSION" "$BUILD" "$TAG" "$NOTES" "$FORCE" "$OUT" <<'PY'
import json, os, sys
path, version, build, tag, notes, force, out = sys.argv[1:]
base = f"https://github.com/imamhossenbu/drive-offer-customer-app/releases/download/{tag}/"
size = lambda f: round(os.path.getsize(os.path.join(out, f)) / 1_000_000)
with open(path, encoding="utf-8") as fh:
    cfg = json.load(fh)
for app, prefix in (("customer", "drive-offer-customer"), ("admin", "drive-offer-admin")):
    sec = cfg.setdefault(app, {})
    sec.update({
        "latestVersion": version,
        "buildNumber": int(build),
        "downloadUrl": base + prefix + ".apk",
        "downloadUrlV7a": base + prefix + "-v7a.apk",
        "sizeMb": size(prefix + ".apk"),
        "forceUpdate": force == "true",
        "releaseNotes": notes,
    })
lst = cfg.setdefault("listener", {})
lst["downloadUrl"] = base + "driver-sms-listener.apk"
lst["downloadUrlV7a"] = base + "driver-sms-listener-v7a.apk"
lst["sizeMb"] = size("driver-sms-listener.apk")
with open(path, "w", encoding="utf-8") as fh:
    json.dump(cfg, fh, ensure_ascii=False, indent=2)
    fh.write("\n")
PY

step "Committing and pushing"
if ! $SKIP_BUILD; then
  git -C "$ADMIN" add pubspec.yaml
  git -C "$ADMIN" commit -q -m "chore(release): $TAG"
  git -C "$ADMIN" push -q origin main
  git -C "$CUST" add pubspec.yaml
fi
git -C "$CUST" add app-config.json
git -C "$CUST" commit -q -m "chore(release): $TAG"
git -C "$CUST" push -q origin main

step "Verifying"
code=$(curl -s -o /dev/null -w '%{http_code}' -L "https://github.com/$REPO/releases/download/$TAG/drive-offer-customer.apk")
[[ "$code" == "200" ]] || die "customer APK download returned HTTP $code"
echo "Customer APK download: OK"
echo
echo "Done. $TAG (build $BUILD) is live."
echo "  Customer page: https://imamhossenbu.github.io/drive-offer-customer-app/"
echo "  Team page:     https://imamhossenbu.github.io/drive-offer-customer-app/admin/"
echo "Apps on an older build will show the update screen (config cache can take a few minutes)."
