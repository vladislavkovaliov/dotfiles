#!/usr/bin/env bash
# install-packages.sh — thin wrapper around pkgs.sh. See pkgs.sh for details.

exec "$(dirname "$0")/pkgs.sh"
