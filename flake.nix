{
  description = "Hydra Doom";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    hydra.url = "github:input-output-hk/hydra/doom";
    cardano-node.url = "github:intersectmbo/cardano-node/8.9.4";
    flake-parts.url = "github:hercules-ci/flake-parts";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    hydra-control-plane.url = "github:cardano-scaling/hydra-control-plane";
    hydra-control-plane-single.url = "github:cardano-scaling/hydra-control-plane/849871d88d21c25cd7fcc493eceadccfde7538f1";
    hydra-doom = {
      url = "github:cardano-scaling/hydra-doom/sl/vite-config-fix";
      flake = false;
    };
    hydra-doom-single = {
      url = "github:cardano-scaling/hydra-doom/sl/single-player-refactor";
      flake = false;
    };
    nix-inclusive.url = "github:input-output-hk/nix-inclusive";
    colmena.url = "github:zhaofengli/colmena";
    sops-nix.url = "github:Mic92/sops-nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, flake-parts, nixpkgs, ... }@ inputs: let
    inherit ((import ./flake/lib.nix {inherit inputs;}).flake.lib) recursiveImports;
    in flake-parts.lib.mkFlake { inherit inputs; } {
      imports = recursiveImports [
        ./flake
        ./perSystem
      ] ++ [
        inputs.process-compose-flake.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
      ];
    };
}
