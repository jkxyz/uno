# Example project

## Nix flakes

Nix flakes let you declaratively specify dependencies and code used in your project.

You can reference other flakes as inputs to your flake, and Nix will pin their versions
in a way which is easy to update. Because the inputs are pinned by their hash, flakes
can be evaluated as a pure function: the same inputs will produce the same output.[^1]

Built outputs are stored by the hash of their inputs under `/nix/store`, so if Nix finds
that the package it's trying to build already exists, it can skip building it again. The
more general Nix term for these outputs is "derivations".

A flake is essentially a file called `flake.nix` stored in a git repository.

The primary input to any flake is the git repository it's stored in. If you change the
files in your repo, the output will be rebuilt when you request it.

The most common input besides this is [nixpkgs](https://github.com/NixOS/nixpkgs).
This is a repository of package definitions and other helpful tools which let you 
install and run things with Nix.

Outputs can be anything from your built application ready to be deployed to production,
to full NixOS configurations which can be applied to a running system. In Uno's case, 
the main output is a text file called `Procfile` which is passed to Foreman.

After we ask Nix to build the `Procfile` output, we get back a path like `/nix/store/xxxxx-Procfile`,
which is then passed as an argument to Foreman.

The `flake.nix` file contains a single top-level attribute set (Nix's name for a map 
or dictionary), with two attributes: `inputs` and `outputs`.

[^1]: This might sound like Nix requires deterministic builds. But the only things 
which determine the hash for a built derivation are its source code and the source code of
all its dependencies. Everything in Nix is built from source, with a hosted binary 
cache to speed things up. External sources have a SHA256 hash specified in their definition.
And so it's possible to get a derivation's hash without actually building anything. Nix 
takes care of all of this transparently.

### Inputs

Inputs are specified as URLs to git repositories.

The most common input you'll see is:

``` nix
inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
```

This line is setting a nested attribute, `inputs.nixpkgs.url`. This is a convenient 
shorthand for `inputs = { nixpkgs = { url = "..."; }; };`. The `nixpkgs` attribute
name is arbitrary but a common convention, and it's just used to pass the input
to our outputs function later.

The URL is pointing to the `nixpkgs-unstable` branch of the `nixos/nixpkgs` repo
on GitHub. When we run for example `nix build` for the first time, Nix will find the 
current HEAD of that branch and store its hash in a file called `flake.lock`. 

#### Updating inputs

In the above example, the version of `nixpkgs` will stay pinned at its initial state
until we ask Nix to update it. To update it, run:

```
$ nix flake lock --update-input nixpkgs
```

This will then look again for the current HEAD of the branch and store its commit hash 
in `flake.lock`.

If something stops working, you can checkout the previous version of `flake.lock` and
you'll be running the same versions you were before.

#### Following inputs

You can set other attributes on an input besides `url`.

Since Uno also has `nixpkgs` as an input, we ideally want it to use the same version
as our flake, so that the packages it uses can be the same as those referenced
elsewhere in the project.

You do this with the `follows` attribute:

``` nix
inputs.uno.url = "github:jkxyz/uno";
inputs.uno.inputs.nixpkgs.follows = "nixpkgs";
```

This specifies that the input named `nixpkgs` in the Uno flake is the same as
the input named `nixpkgs` on the current flake.

### Outputs
