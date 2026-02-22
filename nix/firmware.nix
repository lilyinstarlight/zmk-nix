{ lib
, buildSplitKeyboard
, self
}:

buildSplitKeyboard {
  name = "sofle-firmware";

  src = lib.sourceFilesBySuffices self [ ".board" ".cmake" ".conf" ".defconfig" ".dts" ".dtsi" ".json" ".keymap" ".overlay" ".shield" ".yml" "_defconfig" ];

  board = "nice_nano@2.0.0";
  shield = "sofle_%PART% nice_view_adapter nice_view";

  zephyrDepsHash = "sha256-gsJ17xtoonTMumYhlhsOxItdBhzUXd4gNCyhOY2+IK8=";

  meta = with lib; {
    description = "Keyboard firmware for Sofle RGB with nice!view screens";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ /*lilyinstarlight*/ ];
  };
}
