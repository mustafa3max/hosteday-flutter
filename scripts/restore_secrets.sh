#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# HosteDay Flutter SDK - Secrets Restoration Script
# ------------------------------------------------------------------------------
# Restores backed-up live credentials from .local_secrets/ into example/ for
# local development, testing, and debugging.
# ------------------------------------------------------------------------------

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SECRETS_DIR="$ROOT_DIR/.local_secrets"

if [[ ! -d "$SECRETS_DIR" ]]; then
  echo "❌ Error: Secrets backup directory not found at $SECRETS_DIR"
  echo "Please ensure you have backed up your secrets first."
  exit 1
fi

echo "🔓 [HosteDay] Restoring live credentials from .local_secrets/..."

restore_file() {
  local src="$1"
  local dst="$2"
  if [[ -f "$src" ]]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    echo "  ✓ Restored $(basename "$dst")"
  else
    echo "  ⚠️ Backup file not found: $src"
  fi
}

restore_file "$SECRETS_DIR/lib/hosteday_config.dart" "$ROOT_DIR/lib/hosteday_config.dart"
restore_file "$SECRETS_DIR/example/lib/hosteday_config.dart" "$ROOT_DIR/example/lib/hosteday_config.dart"
restore_file "$SECRETS_DIR/example/web/firebase-config.json" "$ROOT_DIR/example/web/firebase-config.json"
restore_file "$SECRETS_DIR/example/web/firebase-messaging-sw.js" "$ROOT_DIR/example/web/firebase-messaging-sw.js"
restore_file "$SECRETS_DIR/example/android/app/google-services.json" "$ROOT_DIR/example/android/app/google-services.json"
restore_file "$SECRETS_DIR/example/android/google-services.json" "$ROOT_DIR/example/android/google-services.json"
restore_file "$SECRETS_DIR/example/ios/Runner/GoogleService-Info.plist" "$ROOT_DIR/example/ios/Runner/GoogleService-Info.plist"

echo "✨ [HosteDay] Secrets restoration complete! Local environment is ready for testing."
