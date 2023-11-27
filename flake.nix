{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }: let
    forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
  in {
    packages = forAllSystems (system: with nixpkgs.legacyPackages.${system}; {
      default = callPackage ./package.nix {
        inherit self;
        inherit (self.legacyPackages.${system}) buildZephyrPackage;
      };
    });

    legacyPackages = forAllSystems (system: with nixpkgs.legacyPackages.${system}; {
      fetchZephyrDeps = callPackage ./fetcher.nix {};

      buildZephyrPackage = callPackage ./builder.nix {
        inherit (self.legacyPackages.${system}) fetchZephyrDeps;
      };
    });

    devShells = forAllSystems (system: with nixpkgs.legacyPackages.${system}; {
      default = mkShell {
        packages = [
          cmake ninja
          gcc-arm-embedded
          (python3.withPackages (ps: [ ps.west ps.pyelftools ]))
        ];

        env = {
          ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
          GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
        };
      };
    });
  };
}
