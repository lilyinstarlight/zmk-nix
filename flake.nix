{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in {
    lib = {
      buildersFor = pkgs: import ./nix/builders.nix { inherit (pkgs) callPackage; };
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

      flashBlock = pkgs.callPackage ./nix/flash-block.nix {
        inherit firmware;
      };

      uf2-udev-rules = pkgs.callPackage ./nix/uf2-udev-rules {};

      update = pkgs.callPackage ./nix/update.nix {};
    });

    legacyPackages = forAllSystems (system: self.lib.buildersFor nixpkgs.legacyPackages.${system});

    nixosModules = {
      udevRules = ({pkgs, ...}: {
        services.udev.packages = [ self.packages.${pkgs.system}.uf2-udev-rules ];
      });
    };

    overlays = {
      default = final: prev: self.lib.buildersFor prev;
    };

    devShells = forAllSystems (system: let pkgs = nixpkgs.legacyPackages.${system}; in {
      default = pkgs.callPackage ./nix/shell.nix {};
    });

    templates = {
      default = {
        path = ./template;
        description = "Basic template with GitHub Actions for building ZMK firmware with Nix";
        welcomeText = ''
          # Welcome

          ## Getting started

          - Change `buildSplitKeyboard` to `buildKeyboard` in `flake.nix` if not using a split keyboard
          - Edit for the desired ZMK board and shield(s) in `flake.nix`
          - Create and edit `config/<shield>.conf` and `config/<shield>.keymap` to your liking
          - Run `nix run .#flash` to flash firmware


          ## Maintenance

          - Run `nix run .#update` to update West dependencies, including ZMK version, and bump the `zephyrDepsHash` on the derivation
          - GitHub Actions to automatically PR flake lockfile bumps and West dependency bumps are included
          - Using something like Mergify to automatically merge these PRs is recommended - see <https://github.com/lilyinstarlight/zmk-nix/blob/main/.github/mergify.yml> for an example Mergify configuration


          ## Alternative flashers

          - See the readme for alternative flash methods and their use.
        '';
      };
    };
  };
}
