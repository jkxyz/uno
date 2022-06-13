# uno

Uno is a small wrapper around Nix and Foreman for declaratively defining and 
running development services.

On the Nix side, Uno provides a flexible configuration system which lets you 
leverage Nix for whatever simple or complex environment your applications run in:

* Running multiple development processes and applications
* Running multiple versions of Python, Node, Java, etc.
* Running multiple versions of databases

This configuration has all the benefits of Nix: it's easy to share and transfer
between systems and guaranteed to run the same binaries for everyone. Packages
are not installed into the global environment and will be garbage collected 
when you delete your Uno configuration.

On the Foreman side, the `uno` command will use the configuration to generate
a Procfile and run Foreman with your configuration.

See `example/flake.nix` for a comprehensive example and starting point.

**STATUS: Alpha. The API and behavior may change at any time.**

## Usage

The following `flake.nix` contains a default configuration as the 
`unoConfigurations.${system}.default` output, as well as a Nix shell
which contains NodeJS and the Uno CLI. To enter the shell, run 
`nix develop` and then `uno start` to start the default services.

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
          buildInputs = [ 
            uno.packages.${system}.uno 
            pkgs.nodejs 
          ];
        };

        # Create a configuration with the name "default"
        unoConfigurations.default = uno.lib.mkUnoConfiguration {
          # Provide the current system used for initializing nixpkgs
          inherit system;
          
          # Create a Postgres service which will store its data in a relative
          # directory. initdb will be called before starting the service to 
          # create the Postgres data and configuration files
          services.postgres = uno.lib.mkPostgresService {
            inherit system;
            dataDir = "data/postgres";

            # Specify a major version package to override the default
            # package = pkgs.postgresql_14;

            # Change the parameters used to initialize and start
            # host = "0.0.0.0";
            # port = 5433;
            # superuser = "myuser";
          };

          # Execute a binary from a package with args. With this approach, the
          # package is not installed into the shell and does not pollute the
          # global environment
          services.redis = {
            command = "${pkgs.redis}/bin/redis-server --dir data/redis";
          };

          # Execute a binary from the shell environment. With this approach, 
          # npm is assumed to be installed into the devShell or available on 
          # the current PATH. This helps to avoid repetition and allows also
          # using npm to run commands during development
          services.app = {
            # Specify environment variables which will be set for the process
            environment = { PORT = 3000; };
            command = "npm start";
          };
        };
      });
}
```

### Prerequisites

Uno only requires Nix to be installed on your system, with the flakes experimental
feature enabled. Nix is available for macOS and Linux.

### Installation

Once you have Nix installed, the recommended way to install Uno is using a 
`flake.nix` with a `devShell` output in your projects. This has several 
advantages including making it easy to share your whole development 
environment. It also ensures that the version of the Uno CLI is the same as 
the Uno library.

### Flake outputs

* `packages.${system}.uno`
  Package containing the `uno` executable.

* `lib.mkUnoConfiguration`
  A function which takes a set describing the services to run and returns
  a set containing derivations to generate and run the Procfile.
  
  * `system`
    The current system
  * `services.NAME.command`
    The command used to start the service
  * `services.NAME.environment`
    A set of environment variable names to values. 
    Default `{}`
    
* `lib.mkPostgresService`
  A function which takes a set describing a Postgres service and returns a
  service which will initialize and start Postgres.
  
  * `system`
    The current system
  * `dataDir`
    The path to the directory containing the Postgres data and configuration files
  * `package`
    The package in which to find the Postgres binaries
    Default: `nixpkgs.legacyPackages.${system}.postgresql`
  * `host`
    The hostname to listen on
    Default: `"localhost"`
  * `port`
    The port to listen on
    Default: `5432`
  * `initialize`
    Whether to initialize the dataDir before starting Postgres
    Default: `true`
  * `superuser`
    The superuser to create when initializing
    Default: `"postgres"`

### Command line options

Environment variables:

* `UNO_ROOT`
  Sets the root directory, which is used for: 1) Finding the `flake.nix` used to 
  start the configuration, and 2) Resolving relative paths when starting services.
  Setting this allows you to share the same configuration between multiple projects.
  For example you might have a file `~/Code/Work/.envrc` which loads a devShell and
  sets `UNO_ROOT` to `~/Code/Work/nix`. Then you can run Uno from either
  `~/Code/Work/proj1` or `~/Code/Work/proj2`.

## Todo

* [ ] Improve the CLI with help text and more useful arguments
* [ ] Figure out a way to pass args like `--offline` to the nix build command
* [ ] Figure out a way to change the configuration name
