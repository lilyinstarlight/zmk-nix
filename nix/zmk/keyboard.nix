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
, ... } @ args: (buildZephyrPackage.override { inherit python3; }) ((lib.attrsets.removeAttrs args [ "config" "extraWestBuildFlags" "extraCmakeFlags" "enableZmkStudio" ]) // {
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
  ] ++ lib.optional (shield != null) "-DSHIELD=${shield}" ++ extraCmakeFlags;

  preConfigure = ''
    westBuildFlagsArray+=("-DZMK_CONFIG=$(readlink -f ${lib.escapeShellArg config})")

    if [ -d modules/lib/nanopb/generator ]; then
      chmod +x modules/lib/nanopb/generator/{nanopb_generator,protoc,protoc-gen-nanopb}
      patchShebangs modules/lib/nanopb/generator
    fi
  '';
})
