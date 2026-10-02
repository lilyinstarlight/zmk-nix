{ lib
, buildKeyboard
, runCommand
}:

{ name ? "${args.pname}-${args.version}"
, board
, shield ? null
, parts ? [ "left" "right" ]
, centralPart ? (lib.head parts)
, enableZmkStudio ? false
, ... } @ args:

let
  resolveForPart = part: value:
    if lib.isAttrs value then value.${part} or value._
    else if lib.isFunction value then value part
    else value;

  replacePart = part: lib.replaceStrings [ "%PART%" ] [ part ];

  westDeps = args.westDeps or (buildKeyboard ((lib.removeAttrs args [ "name" "board" "shield" "parts" "centralPart" ]) // {
    inherit name;
    board = replacePart centralPart (resolveForPart centralPart board);
    shield = lib.mapNullable (replacePart centralPart) (resolveForPart centralPart shield);
  })).westDeps;
in runCommand name ((lib.removeAttrs args [ "name" "board" "shield" "parts" "centralPart" "zephyrDepsHash" "westDeps" "westRoot" "config" "enableZmkStudio" "extraWestBuildFlags" "extraCmakeFlags" ]) // {
  inherit parts centralPart westDeps;
  inherit (westDeps) westRoot;
} // (lib.genAttrs parts (part:
  buildKeyboard ((lib.removeAttrs args [ "name" "board" "shield" "parts" "centralPart" "enableZmkStudio" "westDeps" ]) // {
    name = "${name}-${part}";
    board = replacePart part (resolveForPart part board);
    shield = lib.mapNullable (replacePart part) (resolveForPart part shield);
    enableZmkStudio = if part == centralPart then enableZmkStudio else false;
    inherit westDeps;
  })
))) ''
  mkdir $out
  for part in $parts; do
    ln -s ''${!part}/zmk.uf2 $out/zmk_"$part".uf2
  done
''
