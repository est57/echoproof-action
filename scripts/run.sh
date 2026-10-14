#!/usr/bin/env bash
set -uo pipefail

report="${RUNNER_TEMP}/echoproof-report.md"
args=(check --config "$IN_CONFIG" --snapshot "$IN_SNAPSHOT" --target "$IN_TARGET" --output "$report")
[[ -n "$IN_BASE" ]] && args+=(--base "$IN_BASE")
[[ -n "$IN_RESET" ]] && args+=(--reset "$IN_RESET")
[[ -n "$IN_NOISE_RUNS" ]] && args+=(--noise-runs "$IN_NOISE_RUNS")
[[ -n "$IN_INTENT" ]] && args+=(--intent "$IN_INTENT")
[[ -n "$IN_INTENT_FILE" ]] && args+=(--intent-file "$IN_INTENT_FILE")
[[ -n "$IN_CODE_DIFF" ]] && args+=(--code-diff "$IN_CODE_DIFF")
while IFS= read -r line; do
  [[ -n "${line// }" ]] && args+=(--allow-writes "$line")
done <<< "$IN_ALLOW_WRITES"
while IFS= read -r line; do
  [[ -n "${line// }" ]] && args+=(--expect "$line")
done <<< "$IN_EXPECT"
[[ -z "${ANTHROPIC_API_KEY:-}" ]] && unset ANTHROPIC_API_KEY

echoproof "${args[@]}"
code=$?
case "$code" in
  0) verdict="pass" ;;
  1) verdict="regression" ;;
  *) verdict="error" ;;
esac
{
  echo "verdict=$verdict"
  echo "report=$report"
} >> "$GITHUB_OUTPUT"
[[ -f "$report" ]] && cat "$report" >> "$GITHUB_STEP_SUMMARY"

if [[ "$verdict" == "regression" && "$IN_FAIL" != "true" ]]; then
  exit 0
fi
exit "$code"
