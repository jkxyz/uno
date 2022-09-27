# Uno

**Declarative development processes with Nix.**

Uno is a small wrapper around [Nix](https://github.com/NixOS/nix) – the cross-platform, purely-functional package manager – and [Foreman](https://github.com/ddollar/foreman).

It manages processes in your development environment like databases, CSS watchers, and the app itself.

* Because Nix is purely-functional, all package versions are pinned in your project, so that everyone runs the same versions. 

* And because you can refer to any pinned package, you can even run multiple versions of programs together, e.g. Postgres 11 and 14.

* Everything runs directly on your machine, without the overhead of Docker and VMs.

Uno lets you define a set of processes using the Nix language:

```nix
uno.lib.mkUnoConfiguration {
  inherit system;
  
  services = {
    redis.command = "${pkgs.redis}/bin/redis-server --data data/redis";
    
    postgres = uno.lib.mkPostgresService {
      inherit system;
      dataDir = "data/postgres";
      superuser = "myuser";
    };
    
    app = {
      environment = { PORT = 3000; };
      command = "npm install && npm start";
    };
  };
}
```

And then start them together from the terminal:

```
$ uno start
```

That single command installs all prerequisite packages and starts the configuration with Foreman.

When you press Ctrl-C, they'll all be stopped.

## Installation

Uno only requires the Nix package manager to be installed. 

Instructions for macOS and Linux can be found here: https://nixos.org/download.html

You will need to enable Flakes by adding the following line to `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

There are many other ways to install and configure Nix, so follow the way which works for you.

## Setup

See the [example project](https://github.com/jkxyz/uno/blob/main/example/flake.nix) to get started with setting up your project.

## Usage

Once you have Uno setup, you can start your configuration by running `uno start` in the same directory as your `flake.nix` file.

### Configurations

`uno start` defaults to running the configuration named `default`.

You can create multiple named configurations as outputs on `unoConfigurations.SYSTEM.CONFIG`, and launch them with `uno start CONFIG`.

### Root directory

Uno looks for configurations by finding a `flake.nix` in the root directory. By default this is the current working directory.

To run Uno from a different directory, you can pass the `--root` option or set `UNO_ROOT`. This option also sets the working directory for all of your processes. Using the env var can be useful if you want to share a single configuration between multiple projects.

As long as Uno can find a `flake.nix` with your config, it can start it from anywhere. 

### Offline mode

By default Nix will use an online cache to fetch packages. It re-queries the cache on each run to see if its local files are up to date.

If you're offline, you can pass the `--offline` option to Uno which will skip checking the cache. If you already have everything prefetched then it will start your configuration as normal.

### Cleaning up

It's good practice to clean up unused packages from the Nix store with `nix-collect-garbage`. To ensure this doesn't delete any packages you're actively using, Uno adds a garbage collection root to your project's directory. If you're finished with Uno and want to clean up the packages you've used, delete the `.uno` directory and run `nix-collect-garbage`.
