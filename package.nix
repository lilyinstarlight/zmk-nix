{ lib
, buildZephyrPackage
, runCommand
, self
}:

let
  buildSofle = side: buildZephyrPackage {
    name = "zmk-sofle";

    src = self;

    westRoot = "config";

    westOutputs = [ "modules" "zephyr" "zmk" ];

    westHash = "sha256-G1hxea7V4sY2j30V8iTjn8c6aXzAhiXmHdfgJ3wTsTw=";

    westBuildFlags = [
      "-s" "zmk/app"
      "-b" "nice_nano_v2"
      "--"
      "-DZMK_CONFIG=/build/source/config"
      "-DSHIELD=sofle_rgb_keyhive_${side} nice_view_adapter nice_view"
    ];
  };
in (runCommand "zmk-config" {} ''
  mkdir $out
  ln -s ${buildSofle "left"}/zmk.uf2 $out/zmk_left.uf2
  ln -s ${buildSofle "right"}/zmk.uf2 $out/zmk_right.uf2
'') // {
  meta = with lib; {
    description = "Keyboard firmware for Sofle RGB, Keyhive variant with nice!view screens";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ lilyinstarlight ];
  };
}
