{ lib
, buildKeyboard
, runCommand
}:

{ name ? "${args.pname}-${args.version}"
, board
, shield ? null
, parts ? [ "left" "right" ]
, ... } @ args:

let
  westDeps = (buildKeyboard ((lib.attrsets.removeAttrs args [ "parts" ]) // {
    inherit name;
  })).westDeps;
in runCommand name ({
  inherit parts westDeps;
} // args // (lib.genAttrs parts (part:
  buildKeyboard ((lib.attrsets.removeAttrs args [ "board" "shield" "parts" ]) // {
    name = "${name}-${part}";
    board = lib.replaceStrings [ "%PART%" ] [ part ] board;
    shield = if shield != null then lib.replaceStrings [ "%PART%" ] [ part ] shield else shield;
    westDeps = args.westDeps or westDeps;
  })
))) ''
  mkdir $out
  for part in $parts; do
    ln -s ''${!part}/zmk.uf2 $out/zmk_"$part".uf2
  done
''
