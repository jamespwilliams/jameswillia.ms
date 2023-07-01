---
title: "Line-by-line explanation of a Nix flake"
date: 2023-17-01:00:20+01:00
---

In this post, I'm going to take a basic Nix flake and try and explain it
line-by-line. My hope is that even someone who doesn't know what Nix is might
still find this post useful. Many introductions to Nix and Nix flakes begin
with lot of theory -- I've tried to avoid that here!

I'm not a Nix expert, so take this with a bit of a pinch of salt. If you
notice a mistake please do let me know by making an issue at
https://github.com/jamespwilliams/jameswillia.ms and I'll happily correct it.
When in doubt, consult the manual or Nix wiki.

Disclaimers over...

## What actually is a flake?

If you want a more authoritative explanation of flakes, see
https://nixos.wiki/wiki/Flakes, but the following section should give you
enough information to understand the rest of this article.

At the most basic level, a Nix flake is a way of instructing Nix how to
build a set of packages deterministically.

Simplifying slightly, flakes are pure functions mapping your packages'
dependencies (with pinned versions) to built packages.

Like any function, flakes have inputs and outputs.

Flakes can have various inputs, but most commonly a flake will define as an
input a particular version of [nixpkgs](https://github.com/NixOS/nixpkgs), the
main repository for Nix packages. The flake will then use packages from that
input to build its packages.

A flake can also have various outputs, but most importantly flakes output a
`packages` set, which contains instructions that tell Nix how to build each of
the packages contained in the flake. Those instructions are called
_derivations_, and they will be executed when `nix build` is run against the
flake. I'll go into more detail about flake outputs later.

## The flake

Let's study a simple Go flake from the set of templates at
https://github.com/NixOS/templates:

```
$ nix flake init --template templates#go
wrote: /home/jpw/line-by-line-flake/flake.nix
wrote: /home/jpw/line-by-line-flake/go.mod
wrote: /home/jpw/line-by-line-flake/flake.lock
wrote: /home/jpw/line-by-line-flake/main.go
```

This template tells Nix how to build a Go application named
`example.com/go-hello`, which simply prints out "Hello Nix!" and exits.

For good measure, let's run the flake:

```
$ nix run
Hello Nix!
```

And let's build it and see what running `nix build` on the flake results in:

```
$ nix build

$ cd result

$ tree
.
└── bin
    └── go-hello

1 directory, 1 file
```

(As you can see, `nix build` builds into a directory called `result` by default.)

As expected, the `go-hello` binary is included in the built package.

Let's have a look at the flake's metadata:

```
$ nix flake metadata
Resolved URL:  path:/home/jpw/line-by-line-flake
Locked URL:    path:/home/jpw/line-by-line-flake?lastModified=1688212312&narHash=sha256-03SbQoI45pfD7yKE2qv1l20uxnzedOa4yNKZjxlOEzk=
Description:   A simple Go package
Path:          /nix/store/hddh0nc00bpfmgx76wyli8pm6bx13g1z-source
Last modified: 2023-07-01 12:51:52
Inputs:
└───nixpkgs: github:NixOS/nixpkgs/77aa71f66fd05d9e7b7d1c084865d703a8008ab7
```

And let's see the outputs of the flake:

```
$ nix flake show
path:/home/jpw/line-by-line-flake?lastModified=1688212312&narHash=sha256-03SbQoI45pfD7yKE2qv1l20uxnzedOa4yNKZjxlOEzk=
├───defaultPackage
│   ├───aarch64-darwin: package 'go-hello-20230701'
│   ├───aarch64-linux: package 'go-hello-20230701'
│   ├───x86_64-darwin: package 'go-hello-20230701'
│   └───x86_64-linux: package 'go-hello-20230701'
├───devShells
│   ├───aarch64-darwin
│   │   └───default: development environment 'nix-shell'
│   ├───aarch64-linux
│   │   └───default: development environment 'nix-shell'
│   ├───x86_64-darwin
│   │   └───default: development environment 'nix-shell'
│   └───x86_64-linux
│       └───default: development environment 'nix-shell'
└───packages
    ├───aarch64-darwin
    │   └───go-hello: package 'go-hello-20230701'
    ├───aarch64-linux
    │   └───go-hello: package 'go-hello-20230701'
    ├───x86_64-darwin
    │   └───go-hello: package 'go-hello-20230701'
    └───x86_64-linux
        └───go-hello: package 'go-hello-20230701'
```

I will explain these outputs more as we go on.

## Breaking down flake.nix line-by-line

A flake is a source tree that contains a `flake.nix` file. That `flake.nix` file tells Nix how to build the flake.

Let's take a look at our `flake.nix`:

### Flake source

```nix
     1	{
     2	  description = "A simple Go package";
       
     3	  # Nixpkgs / NixOS version to use.
     4	  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";
       
     5	  outputs = { self, nixpkgs }:
     6	    let
       
     7	      # to work with older version of flakes
     8	      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
       
     9	      # Generate a user-friendly version number.
    10	      version = builtins.substring 0 8 lastModifiedDate;
       
    11	      # System types to support.
    12	      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
       
    13	      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    14	      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
       
    15	      # Nixpkgs instantiated for supported system types.
    16	      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
       
    17	    in
    18	    {
       
    19	      # Provide some binary packages for selected system types.
    20	      packages = forAllSystems (system:
    21	        let
    22	          pkgs = nixpkgsFor.${system};
    23	        in
    24	        {
    25	          go-hello = pkgs.buildGoModule {
    26	            pname = "go-hello";
    27	            inherit version;
    28	            # In 'nix develop', we don't need a copy of the source tree
    29	            # in the Nix store.
    30	            src = ./.;
       
    31	            # This hash locks the dependencies of this package. It is
    32	            # necessary because of how Go requires network access to resolve
    33	            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
    34	            # details. Normally one can build with a fake sha256 and rely on native Go
    35	            # mechanisms to tell you what the hash should be or determine what
    36	            # it should be "out-of-band" with other tooling (eg. gomod2nix).
    37	            # To begin with it is recommended to set this, but one must
    38	            # remeber to bump this hash when your dependencies change.
    39	            #vendorSha256 = pkgs.lib.fakeSha256;
       
    40	            vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
    41	          };
       
    42	        });
       
    43	      # Add dependencies that are only needed for development
    44	      devShells = forAllSystems (system:
    45	        let
    46	          pkgs = nixpkgsFor.${system};
    47	        in
    48	        {
    49	          default = pkgs.mkShell {
    50	            buildInputs = with pkgs; [ go gopls gotools go-tools ];
    51	          };
    52	        });
       
    53	      # The default package for 'nix build'. This makes sense if the
    54	      # flake provides only one package or there is a clear "main"
    55	      # package.
    56	      defaultPackage = forAllSystems (system: self.packages.${system}.go-hello);
    57	    };
    58	}
```


As promised, I'll try and break this down, line-by-line.

---

#### Line 1

```nix
     1	{
```

The opening bracket on this line marks the beginning of a Nix set. A Nix set is
a set of key-value pairs; in other languages, this would be called a map, a
hash, or a dictionary. The Nix set being defined here defines the flake,
following the specification that Nix expects.

---

#### Line 2

```nix
     2	  description = "A simple Go package";
```

This line defines the flake's description, which will be included in the flake's metadata:

```
$ nix flake metadata
Resolved URL:  path:/home/jpw/line-by-line-flake
Locked URL:    path:/home/jpw/line-by-line-flake?lastModified=1688199275&narHash=sha256-03SbQoI45pfD7yKE2qv1l20uxnzedOa4yNKZjxlOEzk=
Description:   A simple Go package
Path:          /nix/store/hddh0nc00bpfmgx76wyli8pm6bx13g1z-source
Last modified: 2023-07-01 09:14:35
Inputs:
└───nixpkgs: github:NixOS/nixpkgs/77aa71f66fd05d9e7b7d1c084865d703a8008ab7
```

---

#### Lines 3-4

```nix
     3	  # Nixpkgs / NixOS version to use.
     4	  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";
```

This line declares a dependency on the `nixpkgs` flake.

In particular, this line declares that our flake takes a flake named `nixpkgs`
as an input, using a _flake reference_. The URL is one way of writing this, but
you can
[also](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#url-like-syntax)
define a flake reference using an attribute set. The URL reference above is
equivalent to this attribute set:

```nix
           inputs.nixpkgs = {
             id = "nixpkgs";
             ref = "nixos-21.11";
             type = "indirect";
           };
```

The `indirect` flake type means that Nix has to look up the flake in the flake
registry. This (after some indirection) means looking up the reference in [this
JSON
blob](https://github.com/NixOS/flake-registry/blob/8054bfa00d60437297d670ab3296a117e7059a10/flake-registry.json#L269),
which, as you can see, maps the reference to the following:

```json
{
  "owner": "NixOS",
  "ref": "nixpkgs-unstable",
  "repo": "nixpkgs",
  "type": "github"
}
```

(but remember that we're overriding `ref` to `nixos-21.11`).

#### Line 5

```nix
     5	  outputs = { self, nixpkgs }:
```

This line defines `outputs` as a function that accepts an attribute set
containing `self` (the flake itself) and `nixpkgs` (from `inputs`).

Nix will:

* resolve the inputs in `inputs`
* call the `outputs` function with those inputs (and `self`)

#### Line 6

```nix
     6	    let
```

This begins a `let ... in <expr>` statement, which you may be familiar with if you've
used Haskell or another functional language before.

Essentially, `let ... in <expr>` is equivalent to `<expr>`, but `<expr>` can
use the variables assigned between `let` and `in`.

#### Lines 7-10

```nix
     7	      # to work with older version of flakes
     8	      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";
       
     9	      # Generate a user-friendly version number.
    10	      version = builtins.substring 0 8 lastModifiedDate;
```

These lines are used to create a version to pass to `pkgs.buildGoModule`. This
version is not particularly important, from what I can tell -- the flake seems
to works fine even if I hardcode `version` to `1.0`.

#### Lines 11-12

```nix
    11	      # System types to support.
    12	      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
```

Defines a list of architecture and operating system combinations ("systems") to build the flake for.

#### Lines 13-14

```nix
    13	      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
    14	      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
```

This launches us into functional world somewhat... This is defining a function `forallsystems` by partially applying [genattrs](https://github.com/NixOS/nixpkgs/blob/12e01c677c5b849dfc94ff774d509a533b74a053/lib/attrsets.nix#L607).

The long and short of it is that the expression `forallsystems f` will, in our case, return:

```nix
{
    x86_64-linux = (f "x86_64-linux");
    x86_64-darwin = (f "x86_64-darwin");
    # etc...
}
```

Where `f "x86_64-linux"` is the result of applying the function `f` with argument `"x86_64-linux"`.

This function makes it really easy to generate outputs for multiple systems in our flake.

#### Lines 15-16

```nix
    15	      # Nixpkgs instantiated for supported system types.
    16	      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });
```

Essentially, this line imports the appropriate package set from the nixpkgs
flake for all of the systems we're building for, so we can refer to those
packages later in our expression. We use the `forAllSystems` function we
defined above to help us.

Note that this bit:

```nix
import nixpkgs { inherit system; }
```

is equivalent to

```nix
import nixpkgs { system = system }
```

#### Lines 17-18

```nix
    17	    in
    18	    {
```

These lines conclude the assignment part of the `let ... in <expr>` statement,
now we start the outputs expression itself.

#### Line 20

```nix
    20	      packages = forAllSystems (system:
```

Here, we declare the `packages` attribute of the `outputs` expression.

As you might have noticed in the output of `nix flake show` I included earlier, `packages` is a map which is keyed by system name. Each system then gets a set mapping package names to packages. Here's the `packages` set in our flake, as a reminder:

```
    ├───aarch64-darwin
    │   └───go-hello: package 'go-hello-20230701'
    ├───aarch64-linux
    │   └───go-hello: package 'go-hello-20230701'
    ├───x86_64-darwin
    │   └───go-hello: package 'go-hello-20230701'
    └───x86_64-linux
        └───go-hello: package 'go-hello-20230701'
```

In our case, we only have the one package, `go-hello`, but we could add a new `go-hello-2` package to our flake, which would result in:

```
└───packages
    ├───aarch64-darwin
    │   ├───go-hello: package 'go-hello-20230701'
    │   └───go-hello-2: package 'go-hello-20230701'
    ├───aarch64-linux
    │   ├───go-hello: package 'go-hello-20230701'
    │   └───go-hello-2: package 'go-hello-20230701'
    ├───x86_64-darwin
    │   ├───go-hello: package 'go-hello-20230701'
    │   └───go-hello-2: package 'go-hello-20230701'
    └───x86_64-linux
        ├───go-hello: package 'go-hello-20230701'
        └───go-hello-2: package 'go-hello-20230701'
```

In order to build `go-hello`, you could run `nix build .#go-hello`. Nix would then walk this tree of packages, searching for your current system's package set, and then finding the `go-hello` package in that set.

(`nix build` without any arguments builds the "default package", which I'll come to later).

#### Lines 21-23

```nix
    21	        let
    22	          pkgs = nixpkgsFor.${system};
    23	        in
```


Another let-in statement, this time to assign a `pkgs` variable that we can use
to refer to the `nixpkgs` for the system we're currently building for.

#### Line 24

```nix
    24	        {
```

This is the start of the derivation that will be included in the `packages`
output of the flake for this system.


#### Line 25

```nix
    25	          go-hello = pkgs.buildGoModule {
```

This line declares a `go-hello` attribute, which is defined by the output of the `pkgs.buildgomodule` invocation. As a result, the flake will contain a `go-hello` package.

You can find notes on `buildGoModule` [here](https://nixos.org/manual/nixpkgs/stable/#sec-language-go) and [here](https://nixos.wiki/wiki/Go). The implementation, if you're curious, can be found [here](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/go/module.nix).

#### Line 26

```nix
    26	            pname = "go-hello";
```

This `pname` attribute is used for two things.

First, it's used to construct the `name` of the derivation/package built by `buildGoModule`. `buildGoModule` also [tacks the version onto the end](https://github.com/NixOS/nixpkgs/blob/master/pkgs/build-support/go/module.nix#L3). You can see this in the `nix flake show` output:

```
    └───x86_64-linux
        └───go-hello: package 'go-hello-20230701'
```

Second, `pname` is used by `nix run`, in particular:

> When output `apps.<system>.myapp` is not defined, `nix run myapp` runs `<packages or legacyPackages.<system>.myapp>/bin/<myapp.meta.mainProgram or myapp.pname or myapp.name (the non-version part)>`

So, if we change `pname` to `something-else` here, `nix run` would fail by default:

```
$ nix run
error: unable to execute '/nix/store/ipriqvf8hdv7b0hiwfm6g5qmd0hi8ssc-something-else-20230701/bin/something-else': No such file or directory
```

#### Line 27

```nix
    27	            inherit version;
```

This is equivalent to

```nix
    27	            version = version;
```

and is used by `buildGoModule` as I mentioned above to generate the derivation/package's `name`.

#### Line 28-30

```nix
    28	            # In 'nix develop', we don't need a copy of the source tree
    29	            # in the Nix store.
    30	            src = ./.;
```

This tells `buildGoModule` where to find the Go source to build.

#### Line 40

```nix
    31	            # This hash locks the dependencies of this package. It is
    32	            # necessary because of how Go requires network access to resolve
    33	            # VCS.  See https://www.tweag.io/blog/2021-03-04-gomod2nix/ for
    34	            # details. Normally one can build with a fake sha256 and rely on native Go
    35	            # mechanisms to tell you what the hash should be or determine what
    36	            # it should be "out-of-band" with other tooling (eg. gomod2nix).
    37	            # To begin with it is recommended to set this, but one must
    38	            # remeber to bump this hash when your dependencies change.
    39	            #vendorSha256 = pkgs.lib.fakeSha256;
       
    40	            vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
```

I think the comment explains this better than I could!

#### Lines 41-42

```nix
    41	          };
    42	        });
```

These closing brackets finish off the declaration of the `packages` output.

#### Lines 43-44

```nix
    43	      # Add dependencies that are only needed for development
    44	      devShells = forAllSystems (system:
```

In this line, we define a `devShells` output for the flake. This output gives
Nix a derivation to load into the environment when someone runs `nix develop`
against the flake.

In particular, the `default` `devShell` for your system will be loaded when you
run `nix develop`. Like with packages, you can define multiple different
`devShell`s in your flake with different names.

#### Lines 44-46

```nix
    45	        let
    46	          pkgs = nixpkgsFor.${system};
    47	        in
```

This is identical to the let-in statement in the `packages` definition discussed earlier.

#### Lines 48-49

```nix
    48	        {
    49	          default = pkgs.mkShell {
```

These lines create the set which will be assigned to `devShells`, and begin
creating the `default` `devShell`, using `pkgs.mkShell`.

`pkgs.mkShell` is a helper function for creating derivations to use as
development shells.

#### Line 50

```nix
    50	            buildInputs = with pkgs; [ go gopls gotools go-tools ];
```

The `buildInputs` essentially allows us to tell Nix a set of packages to make
available in the `devShell`.

By "make available", I really mean that, when the development shell is launched, Nix will:

* ensure that the given packages are in the Nix store
* update the `PATH` of the shell such that binaries in the given packages can be invoked

#### Line 56

```nix
    56	      defaultPackage = forAllSystems (system: self.packages.${system}.go-hello);
```

This line tells Nix which package to use when `nix build` is called without a
specific package reference.

This `defaultPackage` attribute is actually deprecated, and the recommended
approach nowadays is to instead name the package `default`, like so:

```nix
    20	      packages = forAllSystems (system:
    21	        let
    22	          pkgs = nixpkgsFor.${system};
    23	        in
    24	        {
    25	          default = pkgs.buildGoModule {
    26	            pname = "go-hello";
    27	            inherit version;
```

but using `defaultPackage` still works fine.

## Conclusion

That brings us to the end of the flake. Hopefully this rambling has been useful to at least someone!
