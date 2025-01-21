#!/usr/bin/env bash

# Test if a variable is an integer
is_integer() {
  [[ "$1" =~ ^-?[0-9]+$ ]]
}

# Test if a variable is a float
is_float() {
  [[ "$1" =~ ^-?[0-9]*\.[0-9]+$ ]]
}

# git configuration
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR_ID}+${GITHUB_ACTOR}@users.noreply.github.com"

# Clone the repository
git clone "https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
cd "$(basename ${GITHUB_REPOSITORY})" || exit 1

if [ -z "${BADGE_COLOR}" ]
then
  # mode coverage badge

  # Test BADGE_VALUE and LIMIT_COVERAGE are numbers
  if !  is_float "${BADGE_VALUE}" && ! is_integer "${BADGE_VALUE}" ; then
    echo "BADGE_VALUE is not a number"
    exit 1
  fi
  if !  is_float "${LIMIT_COVERAGE}" && ! is_integer "${LIMIT_COVERAGE}" ; then
    echo "LIMIT_COVERAGE is not a number"
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
gobadger -c "${color}" -t "${BADGE_LABEL}" -v "${BADGE_VALUE}" -o "${BADGE_FILENAME}"
git add "${BADGE_FILENAME}"

# Commit and push
git commit -m "[action gobadger] Update ${BADGE_FILENAME}"
git remote set-url origin https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git
git push

echo "https://raw.githubusercontent.com/wiki/${GITHUB_REPOSITORY}/${BADGE_FILENAME}"
