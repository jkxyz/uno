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

        unoConfigurations.example = self.lib.configuration {
          inherit system;

          processes.echo = {
            environment = { YOUR_NAME = "World"; };
            command = "echo Hello, $YOUR_NAME && sleep 5000";
          };
        };
      }) // {
        lib = {
          configuration = { system, processes }:
            let pkgs = import nixpkgs { inherit system; };
            in rec {
              procfile = pkgs.writeText "Procfile"
                (builtins.concatStringsSep "\n" (builtins.attrValues
                  (builtins.mapAttrs (name:
                    { command, environment ? { } }:
                    let
                      exportStatements = builtins.concatStringsSep "\n"
                        (builtins.attrValues (builtins.mapAttrs (name: value:
                          ''export ${name}="${builtins.toString value}"'')
                          environment));
                      script = pkgs.writers.writeBash name ''
                        ${exportStatements}
                        ${command}
                      '';
                    in "${name}: ${script}") processes)));

              start = pkgs.writers.writeBashBin "start" ''
                exec ${pkgs.foreman}/bin/foreman start --procfile=${procfile} --root=$PWD
              '';
            };

          processes = {
            postgres = { system
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
      };
}
