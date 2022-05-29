{
  inputs = { nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable"; };

  outputs = { self, nixpkgs }: {
    lib = {
      mkUnoConfiguration = { system, services }:
        let
          pkgs = import nixpkgs { inherit system; };
          procfile = pkgs.writeText "Procfile" (builtins.concatStringsSep "\n"
            (builtins.attrValues
              (builtins.mapAttrs (name: value: "${name}: ${value.runner}")
                services)));
        in pkgs.writers.writeBashBin "uno" ''
          exec ${pkgs.foreman}/bin/foreman $@ --procfile ${procfile}
        '';
    };
  };
}
