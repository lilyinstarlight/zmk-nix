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
    "-DSHIELD=${shield}"
  ] ++ extraCmakeFlags;

  preConfigure = ''
    westBuildFlagsArray+=("-DZMK_CONFIG=$(readlink -f ${lib.escapeShellArg config})")
  '';
})
