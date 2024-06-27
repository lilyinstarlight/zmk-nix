{ lib
, buildZephyrPackage
, runCommand
}:

{ board
, shield ? null
, src
, zephyrDepsHash
, name ? "zmk"
, config ? "config"
, extraWestBuildFlags ? []
, extraCmakeFlags ? []
, ... } @ args: buildZephyrPackage ((lib.attrsets.removeAttrs args [ "config" "extraWestBuildFlags" "extraCmakeFlags" ]) // {
  inherit name;

  westRoot = config;

  westBuildFlags = [
    "-s" "zmk/app"
    "-b" board
  ] ++ extraWestBuildFlags ++ [
    "--"
  ] ++ lib.optional (shield != null) "-DSHIELD=${shield}" ++ extraCmakeFlags;

  preConfigure = ''
    westBuildFlagsArray+=("-DZMK_CONFIG=$(readlink -f ${lib.escapeShellArg config})")
  '';
})
