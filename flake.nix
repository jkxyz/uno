{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages = rec {
          uno = pkgs.writers.writeBashBin "uno" (builtins.readFile ./uno.sh);
          default = uno;
        };
      }) // {
        lib = {
          mkUnoConfiguration = { system, services }:
            let pkgs = import nixpkgs { inherit system; };
            in rec {
              procfile = pkgs.writeText "Procfile"
                (builtins.concatStringsSep "\n" (builtins.attrValues
                  (builtins.mapAttrs (name:
                    { command }:
                    "${name}: ${command}")
                    services)));
              foremanWrapper =
                pkgs.writers.writeBashBin "uno-foreman-wrapper" ''
                  exec ${pkgs.foreman}/bin/foreman $@ --procfile ${procfile}
                '';
            };
        };
      };
}
