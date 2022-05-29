{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        unoConfigurations.default = self.lib.mkUnoConfiguration {
          inherit system;
          services.postgres = { runner = "${pkgs.postgresql}/bin/postgres"; };
        };
      }) // {
        lib = {
          mkUnoConfiguration = { system, services }:
            let
              pkgs = import nixpkgs { inherit system; };
              procfile = pkgs.writeText "Procfile"
                (builtins.concatStringsSep "\n" (builtins.attrValues
                  (builtins.mapAttrs (name: value: "${name}: ${value.runner}")
                    services)));
            in pkgs.writers.writeBashBin "uno" ''
              exec ${pkgs.foreman}/bin/foreman $@ --procfile ${procfile}
            '';
        };
      };
}
