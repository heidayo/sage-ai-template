#!/usr/bin/env bash
# Smoke tests for templates/hooks/secret-read-multi-layer.sh
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_helpers.sh
source "${SCRIPT_DIR}/_helpers.sh"

SANDBOX="$(create_sandbox)"
trap 'rm -rf "${SANDBOX}"' EXIT

# --- Block: read tools on secret-bearing paths ---

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: cat .env"
assert_contains "${HOOK_STDERR}" "BLOCKED" "block: stderr has BLOCKED"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env.local')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: cat .env.local"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env.production')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: cat .env.production"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'head -5 ~/.ssh/id_rsa')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: head ~/.ssh/id_rsa"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'less ~/.aws/credentials')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: less ~/.aws/credentials"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'grep token secrets/api.json')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: grep on secrets/ path"

# --- Block: env-variable filtering for secret keys ---

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'printenv | grep API_KEY')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: printenv | grep API_KEY"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'env | grep TOKEN')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: env | grep TOKEN"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'set | grep SECRET')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "2" "block: set | grep SECRET"

# --- Allow: legitimate cases (false positive guard) ---

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env.example')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: cat .env.example (template, not real secret)"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env.sample')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: cat .env.sample"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env.template')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: cat .env.template"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'grep KEY src/main.go')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: grep KEY in source code (variable name search)"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat README.md')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: cat README.md"

run_hook "secret-read-multi-layer.sh" '' "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: empty stdin"

run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'echo hello')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "allow: unrelated command"

# --- profile=minimal: full skip ---

cat > "${SANDBOX}/.sage/config.yaml" <<EOF
hooks:
  profile: minimal
EOF
run_hook "secret-read-multi-layer.sh" "$(bash_input_json 'cat .env')" "${SANDBOX}"
assert_eq "${HOOK_RC}" "0" "minimal profile: cat .env not blocked"
# Restore standard profile
cat > "${SANDBOX}/.sage/config.yaml" <<EOF
hooks:
  profile: standard
EOF

summary_line
