#!/usr/bin/env bash
set -euo pipefail

# Build → package .build/SimpleShowKeys.app → sign → launch.
#   ./run.sh            dev build + launch
#   ./run.sh --release  Developer ID sign + notarize + signed .dmg
#                       (credentials from ~/.config/ssk-signing/notarize.env or the environment)
#
# The dev build is signed with a stable self-signed identity so macOS keeps the
# Accessibility permission across rebuilds (an ad-hoc signature changes every build).

cd "$(dirname "$0")"

APP_BUNDLE=".build/SimpleShowKeys.app"
SIGN_ID="Simple Show Keys Dev"
SIGN_DIR="$HOME/.config/ssk-signing"

ensure_signing_identity() {
  security find-identity -p codesigning 2>/dev/null | grep -q "$SIGN_ID" && return 0
  echo "== create code-signing identity '$SIGN_ID' =="
  mkdir -p "$SIGN_DIR"
  openssl req -new -x509 -days 3650 -nodes -newkey rsa:2048 \
    -keyout "$SIGN_DIR/key.pem" -out "$SIGN_DIR/cert.cer" \
    -subj "/CN=$SIGN_ID" -addext "extendedKeyUsage=codeSigning" >/dev/null 2>&1 || return 0
  openssl pkcs12 -export -inkey "$SIGN_DIR/key.pem" -in "$SIGN_DIR/cert.cer" \
    -out "$SIGN_DIR/id.p12" -passout pass:ssk >/dev/null 2>&1 \
    && security import "$SIGN_DIR/id.p12" -k "$HOME/Library/Keychains/login.keychain-db" \
         -P ssk -T /usr/bin/codesign >/dev/null 2>&1 || true
  rm -f "$SIGN_DIR/key.pem" "$SIGN_DIR/id.p12"
}

sign_app() {
  if codesign --force --sign "$SIGN_ID" "$APP_BUNDLE" >/dev/null 2>&1; then
    echo "Signed with '$SIGN_ID'"
  else
    echo "⚠️  '$SIGN_ID' not usable yet; ad-hoc signing (Accessibility must be re-granted after each rebuild)."
    echo "    Trust it once: Keychain Access → '$SIGN_ID' → Get Info → Trust → Code Signing: Always Trust"
    codesign --force --sign - "$APP_BUNDLE"
  fi
}

if [[ "${1:-}" == "--release" ]]; then
  [[ -f "$SIGN_DIR/notarize.env" ]] && source "$SIGN_DIR/notarize.env"
  export DEV_ID APPLE_ID TEAM_ID APP_PW
  Scripts/notarize.sh
  Scripts/release.sh
  exit 0
fi

Scripts/package_app.sh release
ensure_signing_identity
sign_app
pkill -x ShowKeys 2>/dev/null || true
while pgrep -x ShowKeys >/dev/null; do sleep 0.2; done
open "$APP_BUNDLE"
