#!/usr/bin/env bash
# Copyright (c) 2026 Paul Butcher. All rights reserved.
# Released under Apache 2.0 license as described in the file LICENSE.
# Builds the whole site into _site/. Needs only elan, Node 24 and npm.
set -euo pipefail
cd "$(dirname "$0")/.."
lake build
npm ci --no-fund --no-audit
(cd app && npm ci --no-fund --no-audit && LASM_EDITOR=0 npx vite build)
rm -rf _site
cp -r app/dist _site
