#!/usr/bin/env bash
set -euo pipefail

npm install -g lefthook
lefthook version | head -n1
