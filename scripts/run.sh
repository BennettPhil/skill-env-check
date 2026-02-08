#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: run.sh <TOOL> [TOOL...] [OPTIONS]
       run.sh --file <requirements.txt> [OPTIONS]

Checks if required tools are installed on this machine.

Options:
  --file FILE      Read tool names from file (one per line)
  --format FMT     Output format: text, json (default: text)
  --version        Also check and display tool versions
  --help           Show this help message

Examples:
  run.sh node npm git docker
  run.sh --file .tool-versions
  run.sh python3 pip --format json
EOF
  exit 0
}

TOOLS=()
INPUT_FILE=""
FORMAT="text"
SHOW_VERSION=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) usage ;;
    --file) INPUT_FILE="$2"; shift 2 ;;
    --format) FORMAT="$2"; shift 2 ;;
    --version) SHOW_VERSION=true; shift ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      exit 1
      ;;
    *)
      TOOLS+=("$1")
      shift
      ;;
  esac
done

# Read tools from file
if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File not found: $INPUT_FILE" >&2
    exit 1
  fi
  while IFS= read -r line; do
    line=$(echo "$line" | sed 's/#.*//' | xargs)  # strip comments and whitespace
    [[ -n "$line" ]] && TOOLS+=("$line")
  done < "$INPUT_FILE"
fi

if [[ ${#TOOLS[@]} -eq 0 ]]; then
  echo "Error: No tools specified. Use --help for usage." >&2
  exit 1
fi

# Check each tool
RESULTS=()
OK_COUNT=0
MISSING_COUNT=0

for tool in "${TOOLS[@]}"; do
  # Handle versioned tools (e.g., "node>=18")
  tool_name=$(echo "$tool" | sed 's/[>=<].*//')

  if command -v "$tool_name" >/dev/null 2>&1; then
    status="OK"
    path=$(command -v "$tool_name")
    version=""
    if [[ "$SHOW_VERSION" = true ]]; then
      version=$("$tool_name" --version 2>/dev/null | head -1 || echo "unknown")
    fi
    ((OK_COUNT++))
  else
    status="MISSING"
    path=""
    version=""
    ((MISSING_COUNT++))
  fi

  RESULTS+=("${tool_name}|${status}|${path}|${version}")
done

# Output
if [[ "$FORMAT" = "json" ]]; then
  echo "["
  first=true
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r name status path version <<< "$entry"
    if [[ "$first" = true ]]; then
      first=false
    else
      echo ","
    fi
    printf '  {"name": "%s", "status": "%s", "path": "%s"' "$name" "$status" "$path"
    if [[ "$SHOW_VERSION" = true ]]; then
      printf ', "version": "%s"' "$version"
    fi
    printf '}'
  done
  echo ""
  echo "]"
else
  for entry in "${RESULTS[@]}"; do
    IFS='|' read -r name status path version <<< "$entry"
    if [[ "$status" = "OK" ]]; then
      icon="✓"
      detail="$path"
      if [[ -n "$version" ]]; then
        detail="$path ($version)"
      fi
    else
      icon="✗"
      detail="not found"
    fi
    printf "  %s [%s] %s — %s\n" "$icon" "$status" "$name" "$detail"
  done

  echo ""
  echo "Summary: ${OK_COUNT} ok, ${MISSING_COUNT} missing, $((OK_COUNT + MISSING_COUNT)) total"

  if [[ "$MISSING_COUNT" -gt 0 ]]; then
    exit 2
  fi
fi
