set -e

SYSTEM=$(nix eval --impure --expr builtins.currentSystem)
ROOT=${UNO_ROOT-$PWD}
CONFIG_NAME=default
PROCFILE_URL=path:$ROOT#unoConfigurations.$SYSTEM.$CONFIG_NAME.procfile

nix build --out-link $ROOT/.uno/$CONFIG_NAME/Procfile $PROCFILE_URL

PROCFILE=$(nix path-info $PROCFILE_URL)

foreman $@ --root=$ROOT --procfile=$PROCFILE
