let
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs-channels/archive/nixos-unstable.tar.gz;
  pkgs = import <nixpkgs> {}; 
  unstable = import unstableTarball {};

  shell = pkgs.mkShell {
    buildInputs = [ unstable.hugo ];
  };  
in shell
