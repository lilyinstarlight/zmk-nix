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

      adafruit-nrfutil = pkgs.callPackage ./nix/adafruit-nrfutil.nix {};

      firmware = pkgs.callPackage ./nix/firmware.nix {
        inherit self;
        inherit (self.legacyPackages.${system}) buildSplitKeyboard;
      };

      flash = pkgs.callPackage ./nix/flash.nix {
        inherit firmware;
      };

      flash-nicenano-dfu = pkgs.callPackage ./nix/flash-nicenano-dfu.nix {
        inherit firmware adafruit-nrfutil;
      };

      update = pkgs.callPackage ./nix/update.nix {};
    });

    legacyPackages = forAllSystems (system: self.lib.buildersFor nixpkgs.legacyPackages.${system});

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

          ## Alternative flash methods

          - nice-nano via DFU over serial: change flash to flash = zmk-nix.packages.''${system}.flash-nicenano-dfu.override { inherit firmware; };
        '';
      };
    };
  };
}
