{ lib
, buildKeyboard
, runCommand
}:

{ name ? "${args.pname}-${args.version}"
, board
, shield
, parts ? [ "left" "right" ]
, ... } @ args:

runCommand name ({
  inherit parts;
} // args // (lib.genAttrs parts (part:
  buildKeyboard ((lib.attrsets.removeAttrs args [ "shield" "parts" ]) // {
    name = "${name}-part";
    shield = lib.replaceStrings [ "%PART%" ] [ part ] shield;
  })
))) ''
  mkdir $out
  for part in $parts; do
    ln -s ''${!part}/zmk.uf2 $out/zmk_"$part".uf2
  done
''
