{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        packages.default =
          pkgs.writers.writeBashBin "uno" (builtins.readFile ./uno.sh);
      }) // {
        lib = {
          mkUnoConfiguration = { system, services }:
            let
              pkgs = import nixpkgs { inherit system; };
              procfile = pkgs.writeText "Procfile"
                (builtins.concatStringsSep "\n" (builtins.attrValues
                  (builtins.mapAttrs (name:
                    { runner, args ? [ ] }:
                    "${name}: ${runner} ${builtins.concatStringsSep " " args}")
                    services)));
            in {
              foremanWrapper =
                pkgs.writers.writeBashBin "uno-foreman-wrapper" ''
                  exec ${pkgs.foreman}/bin/foreman $@ --procfile ${procfile}
                '';
            };
        };
      };
}
