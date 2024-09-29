{ mkShell
, cmake
, ninja
, gcc-arm-embedded
, python3
, python3Packages
, lib
, fetchFromGitHub
, extra-pkgs ? []
}:

let
  # Keymap-drawer uses version 3 of `platformdirs` but NixPkgst only has
  # version 4.2 available. It's easier to brging the package from GitHub than
  # creating a flake input for an old version of NixPkgs, just to get this one
  # dependency
  platformdirs3 = python3Packages.buildPythonPackage rec {
    name = "platformdirs";
    version = "3.11.0";

    src = fetchFromGitHub {
      owner = "platformdirs";
      repo = "${name}";
      rev = "${version}";
      sha256 = "sha256-rMPpxwPbqAtvr3RtKQDisqQnCxnBfZdolMUPpDE+tR4=";
    };

    format = "pyproject";

    nativeBuildInputs = [
      python3Packages.hatchling
      python3Packages.hatch-vcs
    ];

    meta = {
      homepage = "https://github.com/platformdirs/platformdirs/tree/3.11.0";
      description = "A small Python module for determining appropriate platform-specific dirs";
      license = lib.licenses.mit;
    };
  };

  # NixPkgs does not offer `keymap-drawer` as a python package nor a
  # stand-alone application, so we have  pull the package into our environment
  keymap-drawer = python3Packages.buildPythonPackage rec {
    name = "keymap-drawer";
    version = "v0.17.0";

    src = fetchFromGitHub {
      owner = "caksoylar";
      repo = "${name}";
      rev = "main";
      sha256 = "sha256-eyCOkoVjK32cbLmC+Vgrge5ikW9nhxWc0XElUa76Ksw=";
    };

    format = "pyproject";

    nativeBuildInputs = [
      python3Packages.poetry-core
    ];

    propagatedBuildInputs = with python3Packages; [
      pcpp
      platformdirs3
      pydantic
      pydantic-settings
      pyparsing
      pyyaml
    ];

    meta = {
      homepage = "https://github.com/caksoylar/keymap-drawer";
      description = "Visualize keymaps that use advanced features like hold-taps and combos, with automatic parsing ";
      license = lib.licenses.mit;
    };
  };
in
mkShell {
  packages = [
    cmake ninja
    (python3.withPackages (ps: [
      # From https://github.com/zmkfirmware/zephyr/blob/HEAD/scripts/requirements-base.txt
      ps.west
      ps.pyelftools
      ps.pyyaml
      ps.pykwalify
      ps.canopen
      ps.packaging
      ps.progress
      ps.psutil
      ps.pylink-square
      ps.pyserial
      ps.requests
      ps.anytree
      ps.intelhex
      keymap-drawer
    ]))
    gcc-arm-embedded
  ]
  ++ extra-pkgs;

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  };
}
