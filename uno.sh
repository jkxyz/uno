#!/usr/bin/env bash

set -e

ROOT="${UNO_ROOT-$PWD}"

ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --offline)
            OFFLINE=1
            shift
            ;;
        --root)
            ROOT="$2"
            shift
            shift
            ;;
        -*|--*)
            echo "Unknown option $1"
            exit 1
            ;;
        *)
            ARGS+=("$1")
            shift
    esac
done

set -- "${ARGS[@]}"

help() {
    cat << EOF
uno - declarative development services with Nix

Usage:

uno [OPTS] COMMAND [CONFIG]

Options:

    --root
        Path to the directory containing a flake.nix with
        an uno configuration. Defaults to current working
        directory. Can also be set with the UNO_ROOT
        environment variable.

    --offline
        Passes the --offline flag to nix when building.

Commands:

    start [CONFIG]
        Starts the specified configuration, or the default
        configuration if none is provided.

EOF
}

case $1 in
    start)
        CONFIG_NAME="${2-default}"
        SYSTEM="$(nix eval --impure --expr builtins.currentSystem)"
        PROCFILE_URL="path:$ROOT#unoConfigurations.$SYSTEM.$CONFIG_NAME.procfile"
        nix build ${OFFLINE:+--offline} --out-link "$ROOT/.uno/$CONFIG_NAME/Procfile" $PROCFILE_URL
        PROCFILE_PATH="$(nix path-info $PROCFILE_URL)"
        foreman start --root="$ROOT" --procfile="$PROCFILE_PATH"
        ;;
    help)
        help
        exit 0
        ;;
    *)
        echo "Unknown command $1"
        help
        exit 1
        ;;
esac
