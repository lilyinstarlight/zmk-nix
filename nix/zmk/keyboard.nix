{ lib
, buildZephyrPackage
, runCommand
, protobuf
, python3
}:

{ board
, shield ? null
, src
, zephyrDepsHash
, name ? "zmk"
, config ? "config"
, extraWestBuildFlags ? []
, extraCmakeFlags ? []
, enableZmkStudio ? false
, ... } @ args: (buildZephyrPackage.override { inherit python3; }) ((lib.removeAttrs args [ "config" "enableZmkStudio" "extraWestBuildFlags" "extraCmakeFlags" ]) // {
  inherit name;

  nativeBuildInputs = lib.optionals enableZmkStudio [
    protobuf
    python3.pythonOnBuildForHost.pkgs.protobuf
    python3.pythonOnBuildForHost.pkgs.grpcio-tools
  ] ++ (args.nativeBuildInputs or []);

  westRoot = config;

  westBuildFlags = [
    "-s" "zmk/app"
    "-b" board
  ] ++ extraWestBuildFlags ++ lib.optionals enableZmkStudio [ "-S" "studio-rpc-usb-uart" ] ++ [
    "--"
  ] ++ lib.optional (shield != null) "-DSHIELD=${shield}" 
    ++ lib.optional enableZmkStudio "-DCONFIG_ZMK_STUDIO=y" 
    ++ extraCmakeFlags;
  postPatch = ''
    if [ -e zephyr/module.yml ]; then
      zmkModuleRoot="$(readlink -f .)"

      cd "$(mktemp -d)"
      mkdir -p "$(dirname ${lib.escapeShellArg config})"
      cp --no-preserve=mode -rt "$(dirname ${lib.escapeShellArg config})" "$zmkModuleRoot/"${lib.escapeShellArg config}
    fi
  '' + (args.postPatch or "");

  preConfigure = ''
    westBuildFlagsArray+=("-DZMK_CONFIG=$(readlink -f ${lib.escapeShellArg config})")

    if [ -n "$zmkModuleRoot" ]; then
      westBuildFlagsArray+=("-DZMK_EXTRA_MODULES=$zmkModuleRoot")
    elif [ -e boards ]; then
      westBuildFlagsArray+=("-DBOARD_ROOT=$(readlink -f .)")
    fi
  '' + (args.preConfigure or "");

  postConfigure = ''
    if [ -d ../modules/lib/nanopb/generator ]; then
      chmod +x ../modules/lib/nanopb/generator/{nanopb_generator,protoc,protoc-gen-nanopb}
      patchShebangs ../modules/lib/nanopb/generator
    fi
  '' + (args.postConfigure or "");
})
