# uno

A wrapper around Nix and Foreman for declaratively defining services in development environments.

## Usage

The following `flake.nix` contains a configuration as the `unoConfigurations.${system}.default` output.

```nix
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
        devShell = pkgs.mkShell {
          buildInputs = [ uno.packages.${system}.default ];
        };
        
        unoConfigurations.default = uno.lib.mkUnoConfiguration {
          inherit system;
          services.postgres = { runner = "${pkgs.postgresql}/bin/postgres"; };
        };
      });
}
```

In a shell, running `uno start` will run Foreman with the default service configuration.
