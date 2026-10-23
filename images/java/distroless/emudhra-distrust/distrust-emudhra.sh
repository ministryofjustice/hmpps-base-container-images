#!/bin/sh
# Block compromised eMudhra intermediates by fingerprint (idempotent).
set -eu

DIR="$(dirname "$0")"
BLOCKED="${JAVA_HOME}/lib/security/blocked.certs"

[ -f "$BLOCKED" ] || { echo "blocked.certs not found: $BLOCKED" >&2; exit 1; }

# Current distroless base images already exclude emSign ECC Root CA - G3 from cacerts.
# blocked.certs is a properties file keyed by fingerprint
[ -n "$(tail -c1 "$BLOCKED")" ] && echo >> "$BLOCKED"
grep -E '^[0-9A-F]{64}$' "$DIR/blocked-fingerprints.txt" | while IFS= read -r fp; do
  grep -qx "$fp" "$BLOCKED" || echo "$fp" >> "$BLOCKED"
done