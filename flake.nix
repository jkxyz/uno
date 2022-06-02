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
                  (builtins.mapAttrs (name:
                    { command, packages ? [ ], enviroment ? { } }:
                    let
                      script = pkgs.writers.writeBash name ''
                        export PATH="${pkgs.lib.makeBinPath packages}"
                        ${command}
                      '';
                    in "${name}: ${script}") services)));

              start = pkgs.writers.writeBashBin "start" ''
                exec ${pkgs.foreman}/bin/foreman start --procfile=${procfile} --root=$PWD
              '';
            };

          mkPostgresService = { system
            , package ? nixpkgs.legacyPackages.${system}.postgresql, dataDir
            , host ? "localhost", port ? 5432, initialize ? true
            , superuser ? "postgres" }:
            let
              pkgs = import nixpkgs { inherit system; };
              initScript = pkgs.writers.writeBash "postgres-init" ''
                if [ ! -f ${dataDir}/postgresql.conf ]; then
                  ${package}/bin/initdb --username ${superuser} ${dataDir}
                fi
              '';
            in {
              command =
                "${initScript} && ${package}/bin/postgres -D ${dataDir} -h ${host} -p ${
                  builtins.toString port
                } -k ''";
            };
        };
      };
}
