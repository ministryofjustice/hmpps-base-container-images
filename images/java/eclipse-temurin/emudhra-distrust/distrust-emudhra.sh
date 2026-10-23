#!/bin/sh
# Distrust eMudhra in the JDK: remove emSign ECC Root CA - G3 from cacerts and block the compromised
# intermediates by fingerprint. Safe to keep once upstream JDKs drop the roots (idempotent).
set -eu

DIR="$(dirname "$0")"
CACERTS="${JAVA_HOME}/lib/security/cacerts"
BLOCKED="${JAVA_HOME}/lib/security/blocked.certs"

[ -f "$CACERTS" ] || { echo "cacerts not found: $CACERTS" >&2; exit 1; }
[ -f "$BLOCKED" ] || { echo "blocked.certs not found: $BLOCKED" >&2; exit 1; }

alias='cn_emsign_ecc_root_ca__g3,o_emudhra_technologies_limited,ou_emsign_pki,c_in [jdk]'
listing=$(keytool -J-Duser.language=en -list -rfc -cacerts -storepass changeit)

if printf '%s\n' "$listing" | grep -Fqx "Alias name: $alias"; then
  keytool -delete -alias "$alias" -cacerts -storepass changeit
  printf 'Deleted certificate: %s\n' "$alias"
else
  printf 'Certificate already absent: %s\n' "$alias"
fi

# blocked.certs is a properties file keyed by fingerprint
[ -n "$(tail -c1 "$BLOCKED")" ] && echo >> "$BLOCKED"
grep -E '^[0-9A-F]{64}$' "$DIR/blocked-fingerprints.txt" | while IFS= read -r fp; do
  grep -qx "$fp" "$BLOCKED" || echo "$fp" >> "$BLOCKED"
done