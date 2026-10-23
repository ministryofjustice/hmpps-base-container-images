#!/bin/sh
# Temporary mitigation for the eMudhra CA key compromise. Removes the emSign ECC Root CA - G3 root
# (the trust anchor for the compromised intermediates; per Oracle's guidance) from cacerts and blocks
# the compromised intermediates by fingerprint. Remove once the base JDK drops the root (idempotent).
set -eu

DIR="$(dirname "$0")"
CACERTS="${JAVA_HOME}/lib/security/cacerts"
BLOCKED="${JAVA_HOME}/lib/security/blocked.certs"

[ -f "$CACERTS" ] || { echo "cacerts not found: $CACERTS" >&2; exit 1; }
[ -f "$BLOCKED" ] || { echo "blocked.certs not found: $BLOCKED" >&2; exit 1; }

# Prints aliases of the emSign ECC Root CA - G3 entry (alias format varies between JDK builds). A keytool failure aborts the build, but no matches is fine.
list_emudhra() {
  listing=$(keytool -list -cacerts -storepass changeit)
  printf '%s\n' "$listing" |
    { grep -i -E 'emsign.?ecc.?root.?ca.*g3' || true; } |
    sed -E 's/, [A-Z][a-z]{2} [0-9]{1,2}, [0-9]{4}, trustedCertEntry,.*$//'
}

aliases=$(list_emudhra)
printf '%s\n' "$aliases" | while IFS= read -r alias; do
  [ -n "$alias" ] || continue
  keytool -delete -alias "$alias" -cacerts -storepass changeit
done

# blocked.certs is a properties file keyed by fingerprint
[ -n "$(tail -c1 "$BLOCKED")" ] && echo >> "$BLOCKED"
grep -E '^[0-9A-F]{64}$' "$DIR/blocked-fingerprints.txt" | while IFS= read -r fp; do
  grep -qx "$fp" "$BLOCKED" || echo "$fp" >> "$BLOCKED"
done

remaining=$(list_emudhra)
if [ -n "$remaining" ]; then
  echo "emSign ECC Root CA - G3 still present in $CACERTS" >&2
  exit 1
fi
