{ lib
, buildKeyboard
, stdenvNoCC
}:

lib.extendMkDerivation {
  constructDrv = stdenvNoCC.mkDerivation;

  extendDrvArgs = 
    finalAttrs:
    { name ? "${args.pname}-${args.version}"
    , board
    , shield ? null
    , parts ? [ "left" "right" ]
    , centralPart ? (lib.head parts)
    , enableZmkStudio ? false
    , ... } @ args:
    let
      westDeps = args.westDeps or (buildKeyboard ((lib.removeAttrs args [ "parts" "centralPart" ]) // {
        inherit name;
      })).westDeps;
    in
    {
      inherit name board shield centralPart westDeps; 
      inherit (westDeps) westRoot;

      buildCommand = args.buildCommand or ''
        mkdir $out
        for part in $parts; do
          ln -s ''${!part}/zmk.uf2 $out/zmk_"$part".uf2
        done
      '';
    }  
    // (lib.genAttrs parts (part:
      buildKeyboard ((lib.removeAttrs args [ "parts" "centralPart" ]) // {
        name = "${name}-${part}";
        board = lib.replaceStrings [ "%PART%" ] [ part ] board;
        shield = if shield != null then lib.replaceStrings [ "%PART%" ] [ part ] shield else shield;
        enableZmkStudio = if part == centralPart then enableZmkStudio else false;
        inherit westDeps;
      })
    ));
}
