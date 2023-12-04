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
  zephyrDepsHash ? "",
  westBuildFlags ? [],
  ...
} @ args: stdenv.mkDerivation (finalAttrs: (lib.attrsets.removeAttrs args [ "zephyrDepsHash" "westRoot" ]) // {
  inherit westBuildFlags;

  nativeBuildInputs = [
    cmake
    git
    ninja
    west
  ] ++ (args.nativeBuildInputs or []);

  westDeps = args.westDeps or (fetchZephyrDeps ({
    name = "${finalAttrs.finalPackage.name}-west-deps";
    hash = zephyrDepsHash;
  }
  // (lib.filterAttrs (name: _: lib.elem name [ "westRoot" ]) args)
  // (lib.filterAttrs (name: _: lib.elem name [ "src" "srcs" "sourceRoot" "prePatch" "patches" "postPatch" ]) finalAttrs)));

  passthru = { inherit (finalAttrs.westDeps) westRoot; };

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  } // (args.env or {});

  configurePhase = args.configurePhase or ''
    runHook preConfigure

    for output in $westDeps/.west $westDeps/*; do
      cp --no-preserve=mode -rt . "$output"
    done

    declare -ag westBuildFlagsArray=(${lib.escapeShellArgs finalAttrs.westBuildFlags})

    if zephyrCmake="$(find "$(pwd)" -path '*/share/zephyr-package/cmake' -print -quit)"; then
      export CMAKE_PREFIX_PATH="$zephyrCmake''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"

      if [ -z "$dontAddZephyrVersion" ]; then
        if (for item in "''${westBuildFlagsArray[@]}"; do [ "$item" = '--' ] && exit 1; done); then
          westBuildFlagsArray+=('--')
        fi
        westBuildFlagsArray+=("-DBUILD_VERSION=$(<"''${zephyrCmake%/share/zephyr-package/cmake}/.git/HEAD)")
      fi
    fi

    runHook postConfigure
  '';

  buildPhase = args.buildPhase or ''
    runHook preBuild

    TERM=dumb west build "''${westBuildFlagsArray[@]}"

    runHook postBuild
  '';

  installPhase = args.installPhase or ''
    runHook preInstall

    mkdir $out
    cp build/*/*.uf2 $out/

    runHook postInstall
  '';

  dontUseNinjaCheck = true;
})
