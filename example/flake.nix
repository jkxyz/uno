{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    uno.url = "github:jkxyz/uno";
    uno.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, uno }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        unoConfigurations.default = uno.lib.configuration {
          inherit system;

          processes = {
            echo = {
              environment = { YOUR_NAME = "World"; };
              command = "echo Hello, $YOUR_NAME && sleep 5000";
            };

            postgres = uno.lib.processes.postgres {
              inherit system;
              dataDir = "data/postgres";
            };

            postgres13 = uno.lib.processes.postgres {
              inherit system;
              package = pkgs.postgresql_13;
              dataDir = "data/postgres13";
              port = 5433;
            };
          };
        };
      });
}
