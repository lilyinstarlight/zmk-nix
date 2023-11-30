{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in {
    lib = {
      buildersFor = pkgs: pkgs.callPackage ./nix/builders.nix {};
    };

    packages = forAllSystems (system: let pkgs = nixpkgs.legacyPackages.${system}; in rec {
      default = firmware;

      firmware = pkgs.callPackage ./nix/firmware.nix {
        inherit self;
        inherit (self.legacyPackages.${system}) buildSplitKeyboard;
      };

      flash = pkgs.callPackage ./nix/flash.nix {
        inherit firmware;
      };
    });

    legacyPackages = forAllSystems (system: self.lib.buildersFor nixpkgs.legacyPackages.${system});

    overlays = {
      default = final: prev: self.lib.buildersFor final;
    };

    devShells = forAllSystems (system: let pkgs = nixpkgs.legacyPackages.${system}; in {
      default = pkgs.callPackage ./nix/shell.nix {};
    });
  };
}
