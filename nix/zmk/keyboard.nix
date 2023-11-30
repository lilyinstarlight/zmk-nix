{ lib
, buildZephyrPackage
, runCommand
}:

{ board
, shield
, src
, zephyrDepsHash
, name ? "zmk"
, config ? "config"
, extraCmakeFlags ? []
, westOutputs ? [ "modules" "zephyr" "zmk" ]
, ... } @ args: buildZephyrPackage ((lib.attrsets.removeAttrs args [ "config" "extraCmakeFlags" ]) // {
  inherit name westOutputs;

  westRoot = config;

  westBuildFlags = [
    "-s" "zmk/app"
    "-b" board
    "--"
    "-DZMK_CONFIG=/build/${src.name or "source"}/${config}"
    "-DSHIELD=${shield}"
  ] ++ extraCmakeFlags;
})
