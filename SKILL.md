---
name: env-check
description: Validates that required development tools are installed on a machine, with version checking and requirements file support.
version: 0.1.0
license: Apache-2.0
---

# Environment Check

## Purpose

Verify that a developer's machine has all required tools installed. Reads tool names from arguments or a requirements file, checks each one, and reports which are present and which are missing. Useful for onboarding, CI setup validation, and project README prerequisites.

## Quick Start

```bash
$ ./scripts/run.sh node npm git docker
  ✓ [OK] node — /usr/local/bin/node
  ✓ [OK] npm — /usr/local/bin/npm
  ✓ [OK] git — /usr/bin/git
  ✗ [MISSING] docker — not found

Summary: 3 ok, 1 missing, 4 total
```

## Usage Examples

### From a Requirements File

```bash
$ echo -e "node\nnpm\ngit\npython3" > .tool-versions
$ ./scripts/run.sh --file .tool-versions
```

### With Version Info

```bash
$ ./scripts/run.sh node python3 --version
  ✓ [OK] node — /usr/local/bin/node (v20.11.0)
  ✓ [OK] python3 — /usr/bin/python3 (Python 3.12.1)
```

### JSON Output

```bash
$ ./scripts/run.sh bash git --format json
[
  {"name": "bash", "status": "OK", "path": "/bin/bash"},
  {"name": "git", "status": "OK", "path": "/usr/bin/git"}
]
```

## Options Reference

| Flag          | Default | Description                            |
|---------------|---------|----------------------------------------|
| `--file FILE` |         | Read tool names from file (one/line)   |
| `--format FMT`| text    | Output format: text, json              |
| `--version`   | false   | Show tool versions                     |
| `--help`      |         | Show usage                             |

## Error Handling

| Exit Code | Meaning                |
|-----------|------------------------|
| 0         | All tools present      |
| 1         | Usage/input error      |
| 2         | One or more tools missing |

## Validation

Run `scripts/test.sh` — 8 assertions covering core, edge cases, file input, JSON output.
