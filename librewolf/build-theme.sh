#!/bin/sh
# Package the Darkmatter LibreWolf theme as librewolf/darkmatter.xpi.
# Install it from about:addons -> gear -> "Install Add-on From File...".
# It is unsigned, so first set xpinstall.signatures.required to false in about:config.
set -e
cd "$(dirname "$0")"
rm -f darkmatter.xpi
guix shell zip -- sh -c 'cd darkmatter && zip -q -r ../darkmatter.xpi .'
echo "Built $(pwd)/darkmatter.xpi"
