#!/usr/bin/env bats

# ddev-litellm add-on tests
# Run locally: bats ./tests/test.bats
# Skip release tests: bats ./tests/test.bats --filter-tags '!release'

setup() {
  set -eu -o pipefail

  export GITHUB_REPO=credevator/ddev-litellm

  TEST_BREW_PREFIX="$(brew --prefix 2>/dev/null || true)"
  export BATS_LIB_PATH="${BATS_LIB_PATH:-}:${TEST_BREW_PREFIX}/lib:/usr/lib/bats"
  bats_load_library bats-assert
  bats_load_library bats-file
  bats_load_library bats-support

  export DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  export PROJNAME="test-ddev-litellm"
  mkdir -p "${HOME}/tmp"
  export TESTDIR="$(mktemp -d "${HOME}/tmp/${PROJNAME}.XXXXXX")"
  export DDEV_NONINTERACTIVE=true
  export DDEV_NO_INSTRUMENTATION=true
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  cd "${TESTDIR}"
  run ddev config --project-name="${PROJNAME}"
  assert_success
  run ddev start -y
  assert_success
}

health_checks() {
  # Verify LiteLLM container is running
  run docker inspect --format='{{.State.Status}}' "ddev-${PROJNAME}-litellm"
  assert_success
  assert_output "running"

  # Allow time for LiteLLM to fully initialize
  sleep 60

  # Verify health endpoint
  run ddev exec curl -sf "http://ddev-${PROJNAME}-litellm:4000/health/liveliness"
  assert_success

  # Verify models endpoint returns valid JSON list
  run ddev exec curl -sf \
    -H "Authorization: Bearer sk-ddev-litellm" \
    "http://ddev-${PROJNAME}-litellm:4000/v1/models"
  assert_success
  assert_output --partial '"object"'

  # Verify litellm-models command works
  run ddev litellm-models
  assert_success
}

teardown() {
  set -eu -o pipefail
  ddev delete -Oy "${PROJNAME}" >/dev/null 2>&1 || true
  [ -n "${TESTDIR:-}" ] && rm -rf "${TESTDIR}"
}

@test "install from directory" {
  set -eu -o pipefail
  echo "# ddev add-on get ${DIR} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${DIR}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}

# bats test_tags=release
@test "install from release" {
  set -eu -o pipefail
  echo "# ddev add-on get ${GITHUB_REPO} with project ${PROJNAME} in $(pwd)" >&3
  run ddev add-on get "${GITHUB_REPO}"
  assert_success
  run ddev restart -y
  assert_success
  health_checks
}
