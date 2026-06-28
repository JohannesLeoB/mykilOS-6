#!/usr/bin/env bash
# airtable_verify.sh — Prüft alle bekannten mykilOS-6-Tabellen in der Mastermind-Base
# Liest PAT + Base-ID aus dem Keychain (Service: com.mykilos6.airtable)
# Schreibt NICHTS — nur GET-Anfragen.
# Ausführen: ./script/airtable_verify.sh

set -euo pipefail

# ── Keychain lesen ────────────────────────────────────────────────────────────
PAT=$(security find-generic-password -s "com.mykilos6.airtable" -a "pat" -w 2>/dev/null || true)
BASE_ID=$(security find-generic-password -s "com.mykilos6.airtable" -a "baseID" -w 2>/dev/null || true)

if [[ -z "$PAT" || -z "$BASE_ID" ]]; then
  echo "❌  Kein Airtable-PAT oder Base-ID im Keychain."
  echo "    → Öffne mykilOS 6 → Einstellungen → Airtable → Zugangsdaten eintragen."
  exit 1
fi

# Prüfe ob Base-ID korrekt ist (muss mit "app" beginnen, nicht "pat")
if [[ "$BASE_ID" == pat* ]]; then
  echo "⚠️   FEHLER: Im Feld 'Base-ID' steht ein PAT-Token, keine Base-ID!"
  echo "    Gespeicherter Wert beginnt mit 'pat...' — das ist falsch."
  echo ""
  echo "    → Öffne mykilOS 6 → Einstellungen → Airtable"
  echo "    → Base-ID Feld: eintragen = appuVMh3KDfKw4OoQ"
  echo "    → PAT-Feld:     dein persönliches Airtable-Token (beginnt mit 'pat...')"
  echo ""
  echo "    Bekannte korrekte Base-ID aus CLAUDE.md: appuVMh3KDfKw4OoQ"
  echo "    Skript verwendet diese als Fallback für den Check:"
  BASE_ID="appuVMh3KDfKw4OoQ"
fi

echo "✅  PAT gefunden (${#PAT} Zeichen)"
echo "✅  Base-ID: $BASE_ID"
echo ""

API="https://api.airtable.com/v0/$BASE_ID"
AUTH="Authorization: Bearer $PAT"
OK=0; FAIL=0

check_table() {
  local NAME="$1"
  local TABLE_ID="$2"
  local RESULT
  RESULT=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "$AUTH" \
    "${API}/${TABLE_ID}?maxRecords=1")
  if [[ "$RESULT" == "200" ]]; then
    echo "  ✅  $NAME ($TABLE_ID)"
    ((OK++)) || true
  else
    echo "  ❌  $NAME ($TABLE_ID) → HTTP $RESULT"
    ((FAIL++)) || true
  fi
}

# ── Kern-Tabellen (immer aktiv) ───────────────────────────────────────────────
echo "── Kern ──────────────────────────────────────────────────────────────────"
check_table "Kunden"                    "tblsz4i1CqpBZUE0N"
check_table "Projekte"                  "tblGJR13OliFt6Ewi"
check_table "Kontakte"                  "tblncfQzQa8TzCZQC"
check_table "Externe Systeme"           "tbl8aoORULVVtphE0"
echo ""

# ── Clockodo ──────────────────────────────────────────────────────────────────
echo "── Clockodo ──────────────────────────────────────────────────────────────"
check_table "Clockodo-Leistungen"       "tblRtsegocdpM8CJd"
check_table "Clockodo-Nutzer"           "tblPbly2br8mR2kaU"
check_table "Clockodo-Buchungen"        "tblYQxlauwej7FD1w"
echo ""

# ── Kalkulation ───────────────────────────────────────────────────────────────
echo "── Kalkulation ───────────────────────────────────────────────────────────"
check_table "Kalkulationen"             "tblO3y2jdmxDnuiZj"
check_table "Kalkulations-Positionen"   "tblNamx3cHTus6gtk"
check_table "Eingehende-Angebote"       "tbliKfs5FnufjdB36"
echo ""

# ── Ergebnis ──────────────────────────────────────────────────────────────────
echo "══════════════════════════════════════════════════════════════════════════"
echo "  $OK von $((OK + FAIL)) Tabellen erreichbar"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "  Nächste Schritte:"
  echo "  • HTTP 401 → PAT abgelaufen → airtable.com/account → neues Token → App-Einstellungen"
  echo "  • HTTP 404 → Tabelle existiert noch nicht oder Base-ID falsch"
  echo "  • HTTP 403 → PAT hat keinen Zugriff auf diese Tabelle"
  exit 1
else
  echo "  Alles grün — Codex kann loslegen."
fi
