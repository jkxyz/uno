{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    uno.url = "path:..";
    uno.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, uno }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in {
        unoConfigurations.default = uno.lib.mkUnoConfiguration {
          inherit system;

          services.postgres = uno.lib.mkPostgresService {
            inherit system;
            dataDir = "data/postgres";
          };
        };
      });
}
