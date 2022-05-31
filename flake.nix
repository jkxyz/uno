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
          uno = pkgs.stdenv.mkDerivation {
            name = "uno";
            src = ./.;
            nativeBuildInputs = [ pkgs.makeWrapper ];
            installPhase = ''
              mkdir -p $out/bin
              cp uno.sh $out/bin/uno
              chmod +x $out/bin/uno
              wrapProgram $out/bin/uno \
               --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.foreman ]}
            '';
          };

          default = uno;
        };

        devShell =
          pkgs.mkShell { buildInputs = [ self.packages.${system}.uno ]; };
      }) // {
        lib = {
          mkUnoConfiguration = { system, services }:
            let pkgs = import nixpkgs { inherit system; };
            in rec {
              procfile = pkgs.writeText "Procfile"
                (builtins.concatStringsSep "\n" (builtins.attrValues
                  (builtins.mapAttrs (name: { command }: "${name}: ${command}")
                    services)));
            };

          mkPostgresService = { system, dataDir, host ? "localhost"
            , package ? nixpkgs.legacyPackages.${system}.postgresql }: {
              command =
                "${package}/bin/postgres -D ${dataDir} -h ${host} -k ''";
            };
        };
      };
}
