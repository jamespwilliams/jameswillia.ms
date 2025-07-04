---
title: "Adventures in building a Go container with Nix"
date: 2022-12-05:00:20+01:00
---

I'd like to preface this article by saying that it is not an authoritative guide, rather it is just me documenting my experience figuring various things out, in the hope that it'll be useful or interesting to someone else. I assume some knowledge of Nix and containerization throughout this article.

## Starting off - setting up a Go Nix flake

Let's start off by creating a Go Nix flake. I found [this article](https://xeiaso.net/blog/nix-flakes-go-programs) which was helpful.

(If you're wondering what a Nix flake is, or why I want to use one rather than just using a regular old Nix derivation, [this article](https://www.tweag.io/blog/2020-05-25-flakes/), written by the original creator of Nix, has a good summary).

So, back to the point... Let's run the commands recommended in the article linked above to set the flake up, using the gomod2nix template:

```bash
$ nix flake init -t github:nix-community/gomod2nix#app
$ git init
$ git add .
```

Okay, all set up. Let's try and run the flake:

```bash
$ nix run
warning: Git tree '/home/jpw/go-container' is dirty
warning: creating lock file '/home/jpw/go-container/flake.lock'
warning: Git tree '/home/jpw/go-container' is dirty
error: unable to execute '/nix/store/0y6yhlqpa6qczqy6cy0kakqqcswm0pzc-myapp-0.1/bin/myapp': No such file or directory
```

Hm, it's not working - `nix run` is trying to execute a binary that doesn't in the derivation. Let's build the derivation to see what's going on under the hood:

```
$ nix build
$ tree result
result
└── bin
    └── gomod2nix-template
```

So the problem is that the binary is called `gomod2nix-template`, but `nix run` is trying to execute `myapp`.

The binary is called `gomod2nix-template` because the `go.mod` in the template declares the module as "example.com/gomod2nix-template".

But why is `nix run` trying to execute the `myapp` binary? To figure that out, we need to take a look at flake.nix:

```nix
{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ gomod2nix.overlays.default ];
          };

        in
        {
          packages.default = pkgs.callPackage ./. { };
          devShells.default = import ./shell.nix { inherit pkgs; };
        })
    );
}
```

A bit of knowledge about how `nix run` works under the hood is needed to understand what's going on here. Per the [Nix wiki](https://nixos.wiki/wiki/Flakes#nix_run):

> When output `apps.<system>.myapp` is not defined, nix run myapp runs `<packages or legacyPackages.<system>.myapp>/bin/<myapp.meta.mainProgram or myapp.pname or myapp.name (the non-version part)>`

In our case, we're running `nix run`, which is equivalent to `nix run default`, and we aren't defining `apps.default` in our flake, so `nix run` is running `${packages.default}/bin/${packages.default.name}`.

So, where does `packages.default` come from? It's defined as `pkgs.callPackage ./. {}`, which comes from `default.nix`:

```nix
{ pkgs ? (
    let
      inherit (builtins) fetchTree fromJSON readFile;
      inherit ((fromJSON (readFile ./flake.lock)).nodes) nixpkgs gomod2nix;
    in
    import (fetchTree nixpkgs.locked) {
      overlays = [
        (import "${fetchTree gomod2nix.locked}/overlay.nix")
      ];
    }
  )
}:

pkgs.buildGoApplication {
  pname = "myapp";
  version = "0.1";
  pwd = ./.;
  src = ./.;
  modules = ./gomod2nix.toml;
}
```

Okay, so that's where `myapp` is coming from. Let's rename the app to `example`, and also rename the go module accordingly.


```bash
$ nix run
warning: Git tree '/home/jpw/go-container' is dirty
Hello flake
```

Yay.

## Containerising the flake

I read [this article](https://community.fly.io/t/running-reproducible-rust-a-fly-and-nix-love-story/3781) to get some information about building Docker containers using Nix. That article is about Rust, but we can ~~steal~~ learn from the containerisation bits.

So the way they're doing it is to stick another output into the flake called `packages.container`, which can be built using `nix build #container`. The relevant snippet is:

```nix
          packages.container = pkgs.dockerTools.buildImage {
            inherit name;
            tag = packages.${name}.version;
            created = "now";
            contents = packages.${name};
            config.Cmd = [ "${packages.${name}}/bin/flynix" ];
          };
```

We can stick similar into our flake, adapting it slightly to the following:

```nix
          packages.container = pkgs.dockerTools.buildImage {
            name = "example";
            tag = "0.1";
            created = "now";
            contents = packages.default;
            config.Cmd = [ "${packages.default}/bin/example" ];
          };
```

Our `flake.nix` now looks like:

``` nix
{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ gomod2nix.overlays.default ];
          };

        in
        rec {
          packages.default = pkgs.callPackage ./. { };
          packages.container = pkgs.dockerTools.buildImage {
            name = "example";
            tag = "0.1";
            created = "now";
            contents = packages.default;
            config.Cmd = [ "${packages.default}/bin/example" ];
          };
          devShells.default = import ./shell.nix { inherit pkgs; };
        })
    );
}
```

(note we've had to add a `rec` before the definition of the flake, so that we can refer to `packages` within the `buildImage` call).


## Building and running the container

```bash
$ nix build .#container
warning: Git tree '/home/jpw/go-container' is dirty
trace: warning: in docker image example: The contents parameter is deprecated. Change to copyToRoot if the contents are designed to be copied to the root filesystem, such as when you use `buildEnv` or similar between contents and your packages. Use copyToRoot = buildEnv { ... }; or similar if you intend to add packages to /bin.
```

Let's ignore that deprecation warning for now...

To run the generated image in Docker:

```
$ docker load < result && docker run --rm example:0.1
e33348d6a90c: Loading layer  2.662MB/2.662MB
Loaded image: example:0.1
Hello flake
```

It works!

## Wait, why is it twice as large as `scratch`?

I was curious about how large the generated image would be.

```
$ docker image ls
REPOSITORY                  TAG       IMAGE ID       CREATED              SIZE
example                     0.1       4ad28c8532ac   About a minute ago   2.66MB
```

Cool, that's pretty small!

Just to double-check, I decided to compare it against an image created using a Dockerfile based on `scratch`:

```Dockerfile
FROM scratch
COPY ./example /bin/example
CMD ["/bin/example"]
```

```bash
$  docker build . -t example-scratch:0.1
[ ... ]
$ docker image ls
REPOSITORY                  TAG       IMAGE ID       CREATED          SIZE
example                     0.1       4ad28c8532ac   2 minutes ago    2.66MB
example-scratch             0.1       75fbb3a82aa9   1 minute ago     1.33MB
```

Hm! The `example-scratch` image is precisely half as large!

Let's have a look at what the `example` image actually contains:

```
$ tar -xvf ../result
./
4ad28c8532ac243b839c40a2bfd597aecb41eef3ac28f2612f787f31cc9b8dce.json
c896502ad29a9f8ec27c42deb1f25d53ade0813bd7497ce9b2d580c2f0c5e9c6/
c896502ad29a9f8ec27c42deb1f25d53ade0813bd7497ce9b2d580c2f0c5e9c6/VERSION
c896502ad29a9f8ec27c42deb1f25d53ade0813bd7497ce9b2d580c2f0c5e9c6/json
c896502ad29a9f8ec27c42deb1f25d53ade0813bd7497ce9b2d580c2f0c5e9c6/layer.tar
manifest.json
repositories

$ cd c896502ad29a9f8ec27c42deb1f25d53ade0813bd7497ce9b2d580c2f0c5e9c6
$ tar -xvf layer.tar
./
./bin/
./bin/example
./nix/
./nix/store/
nix/store/bnga9npn83frx32fqrijdbdqrdrr8mdh-example-0.1/
nix/store/bnga9npn83frx32fqrijdbdqrdrr8mdh-example-0.1/bin/
nix/store/bnga9npn83frx32fqrijdbdqrdrr8mdh-example-0.1/bin/example
```

Hm! The `example` binary exists in the image twice. In a normal Nix environment, `/bin/example` would be a symlink to `/nix/store/bnga9npn83frx32fqrijdbdqrdrr8mdh-example-0.1/bin/example`, but not here. I'm not sure why this is, exactly.

In order to fix this, we need to control which files get included in the built image. Conveniently, the solution to that also solves the deprecation warning we see when we build the container:

```bash
$ nix build .#container
warning: Git tree '/home/jpw/go-container' is dirty
trace: warning: in docker image example: The contents parameter is deprecated. Change to copyToRoot if the contents are designed to be copied to the root filesystem, such as when you use `buildEnv` or similar between contents and your packages. Use copyToRoot = buildEnv { ... }; or similar if you intend to add packages to /bin.
```

It recommends using `copyToRoot`, rather than `contents`. [This article](http://ryantm.github.io/nixpkgs/builders/images/dockertools/) has notes on how to use `copyToRoot`. Notably, it has a `pathsToLink` which lets us do exactly what we want to do - we can make Nix only link files under `/bin/`, which will avoid the duplicate files in the image.

So, after switching to that approach, our `flake.nix` looks like:

```nix
{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ gomod2nix.overlays.default ];
          };

        in
        rec {
          packages.default = pkgs.callPackage ./. { };
          packages.container = pkgs.dockerTools.buildImage {
            name = "example";
            tag = "0.1";
            created = "now";
            copyToRoot = pkgs.buildEnv {
              name = "image-root";
              paths = [ packages.default ];
              pathsToLink = [ "/bin" ];
            };
            config.Cmd = [ "${packages.default}/bin/example" ];
          };
          devShells.default = import ./shell.nix { inherit pkgs; };
        })
    );
}
```

We use `pathsToLink` to tell Nix to only include files under `/bin` in the environment that gets copied in to the image.

Let's build it and see what the image size is:

```bash
$ docker load < result
$ docker image ls
REPOSITORY                  TAG       IMAGE ID       CREATED          SIZE
example                     0.1       93d153753fd9   36 seconds ago   1.33MB
```

It worked!

## Spring cleaning

I'm not sure I really like that `flake.nix` contains application-specific code, like the path to the binary. For simplicity, let's split out the container building into a separate file.

We can do this like so - here's `container.nix`:

```nix
{ pkgs, package }:

pkgs.dockerTools.buildImage {
  name = "example";
  tag = "0.1";
  created = "now";
  copyToRoot = pkgs.buildEnv {
    name = "image-root";
    paths = [ package ];
    pathsToLink = [ "/bin" ];
  };
  config.Cmd = [ "${package}/bin/example" ];
}
```

Here's `flake.nix`:

```nix
{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";

  outputs = { self, nixpkgs, flake-utils, gomod2nix }:
    (flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ gomod2nix.overlays.default ];
          };

        in
        rec {
          packages.default = pkgs.callPackage ./. { };
          packages.container = pkgs.callPackage ./container.nix { package = packages.default; };
          devShells.default = import ./shell.nix { inherit pkgs; };
        })
    );
}
```

So, we've split the container building code into a separate Nix expression, in a separate file, that accepts the package from the flake through its `packages` argument.

Let's check it works:

```
$ git add container.nix
$ nix build .#container
$ docker load < result && docker run --rm example:0.1
ace5c9ecfd0b: Loading layer  1.341MB/1.341MB
The image example:0.1 already exists, renaming the old one with ID sha256:93d153753fd935d932be43c2673a5f1a163809f2bcb8ae0867d70426f9ddcf93 to empty string
Loaded image: example:0.1
Hello flake
```

(Note that we need to run `git add container.nix` before rebuilding. When nix builds a flake from a Git repository, unstaged Git changes will be ignored).

Good to see it still works!

That concludes my evening's exploration of building a Go container image with Nix.
