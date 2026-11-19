#!/usr/bin/env bash
# Copyright (c) 2026 Paul Butcher. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.
# Prints the public API of Inkproof.Demos, one line per declaration; CI compares it with API.lock.
# Regenerate with: scripts/api-lock.sh > API.lock
set -euo pipefail
cd "$(dirname "$0")/../test"
lake build InkproofDemos >&2
lake exe api-lock Inkproof.Demos
