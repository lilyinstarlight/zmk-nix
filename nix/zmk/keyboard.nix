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
, extraCmakeFlags ? []
, ... } @ args: buildZephyrPackage ((lib.attrsets.removeAttrs args [ "config" "extraCmakeFlags" ]) // {
  inherit name;

  westRoot = config;

  westBuildFlags = [
    "-s" "zmk/app"
    "-b" board
    "--"
  ] ++ lib.optional (shield != null) "-DSHIELD=${shield}" ++ extraCmakeFlags;

  preConfigure = ''
    westBuildFlagsArray+=("-DZMK_CONFIG=$(readlink -f ${lib.escapeShellArg config})")
  '';
})
