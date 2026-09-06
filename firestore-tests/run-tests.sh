#!/usr/bin/env bash
# Runs the Firestore rules suite against the emulator.
#
# firebase-tools >= 15 needs a JDK 21+. macOS dev machines often still default
# to 17, so fall back to the JBR that ships with Android Studio rather than
# making everyone install another JDK. CI sets up Java 21 directly.
set -euo pipefail

java_major() {
  "$1/bin/java" -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/'
}

pick_jdk() {
  if command -v java >/dev/null 2>&1; then
    local cur
    cur=$(java -version 2>&1 | head -1 | sed -E 's/.*version "([0-9]+).*/\1/')
    [ "$cur" -ge 21 ] 2>/dev/null && return 0
  fi
  for candidate in \
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
    "/opt/homebrew/opt/openjdk@21" \
    "/opt/homebrew/opt/openjdk"; do
    if [ -x "$candidate/bin/java" ] && [ "$(java_major "$candidate")" -ge 21 ] 2>/dev/null; then
      export JAVA_HOME="$candidate"
      export PATH="$JAVA_HOME/bin:$PATH"
      echo "Using JDK 21+ from: $candidate"
      return 0
    fi
  done
  echo "ERROR: the Firestore emulator needs a JDK 21+; none found." >&2
  exit 1
}

pick_jdk
exec npx firebase emulators:exec --only firestore --project you-app-test "npx mocha --timeout 20000"
