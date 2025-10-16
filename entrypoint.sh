#!/usr/bin/env bash

set -euo pipefail

# Test if a variable is an integer
is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

# Test if a variable is a float
is_float() {
  [[ "$1" =~ ^-?[0-9]*\.[0-9]+$ ]]
}

# Validate filename to prevent path traversal
validate_filename() {
  if [[ "$1" =~ [./] ]] || [[ "$1" =~ ^- ]]; then
    echo "Error: Invalid filename '$1' - must not contain '.', '/', or start with '-'" >&2
    exit 1
  fi
}

# Validate required environment variables
if [[ -z "${GITHUB_TOKEN:-}" ]] || [[ -z "${GITHUB_ACTOR:-}" ]] || [[ -z "${GITHUB_REPOSITORY:-}" ]] || [[ -z "${BADGE_FILENAME:-}" ]]; then
  echo "Error: Required environment variables are missing" >&2
  exit 1
fi

# Validate badge filename
validate_filename "${BADGE_FILENAME}"

# git configuration
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR_ID}+${GITHUB_ACTOR}@users.noreply.github.com"

# Configure git credential helper to avoid token exposure in logs
git config --global credential.helper store
echo "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials

# Clone the repository with shallow clone for performance
if ! git clone --depth 1 "https://github.com/${GITHUB_REPOSITORY}.git"; then
  echo "Error: Failed to clone wiki repository" >&2
  exit 1
fi
cd "$(basename "${GITHUB_REPOSITORY}")" || exit 1

if [ -z "${BADGE_COLOR}" ]
then
  # mode coverage badge

  # Test BADGE_VALUE and LIMIT_COVERAGE are numbers
  if !  is_float "${BADGE_VALUE}" && ! is_integer "${BADGE_VALUE}" ; then
    echo "Error: BADGE_VALUE is not a number" >&2
    exit 1
  fi
  if !  is_float "${LIMIT_COVERAGE}" && ! is_integer "${LIMIT_COVERAGE}" ; then
    echo "Error: LIMIT_COVERAGE is not a number" >&2
    exit 1
  fi

  if (( $(echo "$BADGE_VALUE < $LIMIT_COVERAGE" | bc -l) )); then
    export color=${BADGE_COLOR_UNDER_LIMIT}
    echo "Coverage is under the limit"
  else
    export color=${BADGE_COLOR_OVER_LIMIT}
    echo "Coverage is over the limit"
  fi
  # Add % to the badge value
  export BADGE_VALUE="${BADGE_VALUE}%"
else
  # mode: custom badge
  export color=${BADGE_COLOR}
fi

# Generate the badge
if ! gobadger -c "${color}" -t "${BADGE_LABEL}" -v "${BADGE_VALUE}" -o "${BADGE_FILENAME}"; then
  echo "Error: Failed to generate badge" >&2
  exit 1
fi

# Check if badge file was created
if [[ ! -f "${BADGE_FILENAME}" ]]; then
  echo "Error: Badge file was not created" >&2
  exit 1
fi

git add "${BADGE_FILENAME}"

# Commit only if there are changes
if ! git diff-index --quiet HEAD --; then
  if ! git commit -m "[action gobadger] Update ${BADGE_FILENAME}"; then
    echo "Error: Failed to commit badge" >&2
    exit 1
  fi

  # Push changes (credentials already configured)
  if ! git push; then
    echo "Error: Failed to push to wiki repository" >&2
    exit 1
  fi
  echo "Badge updated successfully"
else
  echo "No changes to commit"
fi

echo "https://raw.githubusercontent.com/wiki/${GITHUB_REPOSITORY}/${BADGE_FILENAME}"
