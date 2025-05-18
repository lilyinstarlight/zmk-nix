{ lib
, stdenv
, fetchZephyrDeps
, cmake
, ninja
, gcc-arm-embedded
, git
, python3
}:

{
  zephyrDepsHash ? "",
  westBuildFlags ? [],
  ...
} @ args: stdenv.mkDerivation (finalAttrs: (lib.removeAttrs args [ "zephyrDepsHash" "westRoot" ]) // {
  inherit westBuildFlags;

  nativeBuildInputs = [
    cmake
    git
    ninja
    python3.pythonOnBuildForHost.pkgs.west
    python3.pythonOnBuildForHost.pkgs.pyelftools
  ] ++ (args.nativeBuildInputs or []);

  westDeps = args.westDeps or (fetchZephyrDeps ({
    name = "${finalAttrs.finalPackage.name}-west-deps";
    hash = zephyrDepsHash;
  }
  // (lib.filterAttrs (name: _: lib.elem name [ "westRoot" ]) args)
  // (lib.filterAttrs (name: _: lib.elem name [ "src" "srcs" "sourceRoot" "prePatch" "patches" "postPatch" ]) finalAttrs)));

  inherit (finalAttrs.westDeps) westRoot;

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  } // (args.env or {});

  configurePhase = args.configurePhase or ''
    declare -ag westBuildFlagsArray=(${lib.escapeShellArgs finalAttrs.westBuildFlags})

    runHook preConfigure

    cp --no-preserve=mode -rt . "$westDeps"/*

    mkdir -p .west
    cat >.west/config <<EOF
    [manifest]
    path = $westRoot
    file = west.yml
    EOF

    if zephyrRoot="$(dirname "$(dirname "$(find "$(pwd)" -path '*/share/zephyr-package/cmake' -printf '%h' -quit)")")"; then
      addCMakeParams "$zephyrRoot"

      if [ -z "$dontAddZephyrVersion" ]; then
        if (for item in "''${westBuildFlagsArray[@]}"; do [ "$item" = '--' ] && exit 1; done); then
          westBuildFlagsArray+=('--')
        fi
        westBuildFlagsArray+=("-DBUILD_VERSION=$(<"$zephyrRoot"/.git/HEAD)")
      fi
    fi

    west build -d "''${cmakeBuildDir:=build}" --cmake-only "''${westBuildFlagsArray[@]}"

    cd "$cmakeBuildDir"

    runHook postConfigure
  '';

  installPhase = args.installPhase or ''
    runHook preInstall

    mkdir $out
    cp */*.uf2 $out/
    cp */*.hex $out/

    runHook postInstall
  '';
})
