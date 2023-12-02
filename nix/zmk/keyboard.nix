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
, ... } @ args: buildZephyrPackage ((lib.attrsets.removeAttrs args [ "config" "extraCmakeFlags" ]) // {
  inherit name;

  westRoot = config;

  westBuildFlags = [
    "-s" "zmk/app"
    "-b" board
    "--"
    "-DZMK_CONFIG=/build/${src.name or "source"}/${config}"
    "-DSHIELD=${shield}"
  ] ++ extraCmakeFlags;
})
