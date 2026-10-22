#!/bin/sh
# Distrust eMudhra in the JDK: remove its roots from cacerts and block the compromised
# intermediates by fingerprint. Safe to keep once upstream JDKs drop the roots (idempotent).
set -eu

DIR="$(dirname "$0")"
CACERTS="${JAVA_HOME}/lib/security/cacerts"
BLOCKED="${JAVA_HOME}/lib/security/blocked.certs"

list_emudhra() {
  keytool -list -keystore "$CACERTS" -storepass changeit 2>/dev/null |
    grep -i -E 'emudhra|emsign' |
    sed -E 's/, [A-Z][a-z]{2} [0-9]{1,2}, [0-9]{4}, trustedCertEntry,.*$//' || true
}

list_emudhra | while IFS= read -r alias; do
  keytool -delete -alias "$alias" -keystore "$CACERTS" -storepass changeit
done

# blocked.certs is a properties file keyed by fingerprint
[ -n "$(tail -c1 "$BLOCKED")" ] && echo >> "$BLOCKED"
grep -E '^[0-9A-F]{64}$' "$DIR/blocked-fingerprints.txt" | while IFS= read -r fp; do
  grep -qx "$fp" "$BLOCKED" || echo "$fp" >> "$BLOCKED"
done

if [ -n "$(list_emudhra)" ]; then
  echo "eMudhra entries still present in $CACERTS" >&2
  exit 1
fi
