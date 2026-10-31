#!/usr/bin/env bash
# Run by the manual GitHub Actions production deployment only.
set -Eeuo pipefail

DEPLOY_ROOT="$1"
WEB_ROOT="$2"
ARCHIVE="$3"
STAMP="$(date +%Y%m%d-%H%M%S)"
RELEASE="$DEPLOY_ROOT/flutter-web-$STAMP"
BACKUP="$DEPLOY_ROOT/flutter-web-backup-$STAMP"

test -f "$ARCHIVE"
mkdir -p "$RELEASE" "$BACKUP"
tar -xzf "$ARCHIVE" -C "$RELEASE"
test -f "$RELEASE/index.html"
test -f "$RELEASE/main.dart.js"

# Only Flutter build artifacts are changed. admin/, api/, releases/ and .htaccess
# under the main website remain untouched.
for item in assets canvaskit favicon.png firebase-messaging-sw.js flutter.js flutter_bootstrap.js flutter_service_worker.js index.html logo.png main.dart.js manifest.json style.css version.json; do
  if [ -e "$WEB_ROOT/$item" ]; then
    mv "$WEB_ROOT/$item" "$BACKUP/$item"
  fi
  if [ -e "$RELEASE/$item" ]; then
    cp -a "$RELEASE/$item" "$WEB_ROOT/"
  fi
done

chmod -R u+rwX,go+rX "$WEB_ROOT/assets"
curl --fail --show-error --max-time 20 --retry 2 https://drokpharma.in/

# Retention is intentionally review-first on shared hosting.
find "$DEPLOY_ROOT" -mindepth 1 -maxdepth 1 -type d \( -name 'flutter-web-*' -o -name 'flutter-web-backup-*' \) -mtime +7 -print 2>/dev/null || true
echo "Flutter web deployed: $RELEASE"
