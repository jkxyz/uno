#!/usr/bin/env bash

set -e

help() {
    cat << EOF
uno - declarative development processes with Nix

Usage:

uno [OPTS] COMMAND [CONFIG]

Options:

    --root DIR
        Path to the directory containing a flake.nix with
        an uno configuration. Defaults to current working
        directory. Can also be set with the UNO_ROOT
        environment variable.

    -m, --formation process=num[,...]
        The number of processes to run.

    --offline
        Passes the --offline flag to nix when building.

Commands:

    start [CONFIG]
        Starts the specified configuration, or the default
        configuration if none is provided.
EOF
}

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
        -m|--formation)
            FORMATION="$2"
            shift
            shift
            ;;
        --help|-h)
            help
            exit 0
            ;;
        -*|--*)
            echo "Unknown option $1"
            help
            exit 1
            ;;
        *)
            ARGS+=("$1")
            shift
    esac
done

set -- "${ARGS[@]}"

case $1 in
    start)
        CONFIG_NAME="${2-default}"
        SYSTEM="$(nix eval --impure --expr builtins.currentSystem)"
        PROCFILE_URL="path:$ROOT#unoConfigurations.$SYSTEM.$CONFIG_NAME.procfile"
        nix build ${OFFLINE:+--offline} --out-link "$ROOT/.uno/$CONFIG_NAME/Procfile" $PROCFILE_URL
        PROCFILE_PATH="$(nix path-info $PROCFILE_URL)"
        foreman start --root="$ROOT" --procfile="$PROCFILE_PATH" ${FORMATION:+--formation=$FORMATION}
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
