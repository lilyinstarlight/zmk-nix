{ lib
, stdenv
, fetchZephyrDeps
, cmake
, ninja
, gcc-arm-embedded
, git
, python3
}:

let
  west = python3.withPackages (ps: [ ps.west ps.pyelftools ]);
in

{
  westHash ? "",
  westRoot ? ".",
  westBuildFlags ? [],
  ...
} @ args: stdenv.mkDerivation (finalAttrs: (lib.attrsets.removeAttrs args [ "westHash" ]) // {
  nativeBuildInputs = [
    cmake
    git
    ninja
    west
  ];

  westDeps = fetchZephyrDeps ({
    name = "${finalAttrs.finalPackage.name}-west-deps";
    hash = westHash;
  } // lib.filterAttrs (name: _: lib.elem name [ "westRoot" "westOutputs" "src" "srcs" "sourceRoot" "prePatch" "patches" "postPatch" ]) finalAttrs);

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  };

  configurePhase = ''
    runHook preConfigure

    for output in $westDeps/.west $westDeps/*; do
      cp --no-preserve=mode -rt . "$output"
    done

    declare -ag westBuildFlagsArray=(${lib.escapeShellArgs finalAttrs.westBuildFlags})

    if [ -d zephyr ]; then
      export CMAKE_PREFIX_PATH="$(pwd)/zephyr/share/zephyr-package/cmake:$CMAKE_PREFIX_PATH"

      if [ -z "$dontAddZephyrVersion" ]; then
        if (for item in "''${westBuildFlagsArray[@]}"; do [ "$item" = '--' ] && exit 1; done); then
          westBuildFlagsArray+=('--')
        fi
        westBuildFlagsArray+=("-DBUILD_VERSION=$(<zephyr/.git/HEAD)")
      fi
    fi

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    west build "''${westBuildFlagsArray[@]}"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    cp build/*/*.uf2 $out/

    runHook postInstall
  '';
})
