{ lib
, buildSplitKeyboard
, self
}:

buildSplitKeyboard {
  name = "sofle-firmware";

  src = lib.sourceFilesBySuffices self [ ".conf" ".keymap" ".yml" ];

  board = "nice_nano_v2";
  shield = "sofle_rgb_keyhive_%PART% nice_view_adapter nice_view";

  zephyrDepsHash = "sha256-AGGVttJupaBwEiB3XQfR0PVb4GFrvJMIkVYpWkKYyoM=";

  meta = with lib; {
    description = "Keyboard firmware for Sofle RGB, Keyhive variant with nice!view screens";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ lilyinstarlight ];
  };
}
