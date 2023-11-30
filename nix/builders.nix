{ callPackage }:

rec {
  fetchZephyrDeps = callPackage ./zephyr/fetcher.nix {};

  buildZephyrPackage = callPackage ./zephyr/builder.nix {
    inherit fetchZephyrDeps;
  };

  buildKeyboard = callPackage ./zmk/keyboard.nix {
    inherit buildZephyrPackage;
  };

  buildSplitKeyboard = callPackage ./zmk/split.nix {
    inherit buildKeyboard;
  };
}
