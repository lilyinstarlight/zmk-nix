{ lib
, buildSplitKeyboard
, self
}:

buildSplitKeyboard {
  name = "sofle-firmware";

  src = lib.sourceFilesBySuffices self [ ".conf" ".keymap" ".dtsi" ".yml" ".shield" ".overlay" ".defconfig" ];

  board = "nice_nano_v2";
  shield = "sofle_%PART% nice_view_adapter nice_view";

  zephyrDepsHash = "sha256-TzYv3gXTtjrVRjepyCmq06QpPrZ0xUAsAWgXPPhPo6k=";

  meta = with lib; {
    description = "Keyboard firmware for Sofle RGB with nice!view screens";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ /*lilyinstarlight*/ ];
  };
}
