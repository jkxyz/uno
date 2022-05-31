set -e

SYSTEM=$(nix eval --impure --expr builtins.currentSystem)
ROOT=${UNO_ROOT-$PWD}
PROCFILE_URL="path:$ROOT#unoConfigurations.$SYSTEM.default.procfile"

nix build --no-link $PROCFILE_URL

PROCFILE=$(nix path-info $PROCFILE_URL)

foreman $@ --root=$ROOT --procfile=$PROCFILE
