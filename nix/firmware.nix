{ lib
, buildSplitKeyboard
, self
}:

buildSplitKeyboard {
  name = "sofle-firmware";

  src = lib.sourceFilesBySuffices self [ ".conf" ".keymap" ".dtsi" ".yml" ".shield" ".overlay" ".defconfig" ];

  board = "nice_nano_v2";
  shield = "sofle_%PART% nice_view_adapter nice_view";

  zephyrDepsHash = "sha256-qR3b0ooc1eXZ7r4OKGqFAqb2yH8novXFVRlkyE166dc=";

  meta = with lib; {
    description = "Keyboard firmware for Sofle RGB with nice!view screens";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ lilyinstarlight ];
  };
}
