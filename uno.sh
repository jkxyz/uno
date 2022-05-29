ACTION="$1"
SYSTEM=$(nix eval --impure --expr "builtins.currentSystem")
CONFIG_NAME="${2:-default}"
FLAKE=".#unoConfigurations.$SYSTEM.$CONFIG_NAME.foremanWrapper"

nix build --no-link $FLAKE

FOREMAN_WRAPPER="$(nix path-info $FLAKE)/bin/uno-foreman-wrapper"

$FOREMAN_WRAPPER $ACTION
