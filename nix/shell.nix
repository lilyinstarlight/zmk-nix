{ mkShell
, cmake
, gcc-arm-embedded
, ninja
, protobuf
, python3
, extraPackages ? []
, extraPythonPackages ? (ps: [])
}:

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
      # For ZMK Studio builds
      ps.protobuf
      ps.grpcio-tools
    ] ++ (extraPythonPackages ps)))
    gcc-arm-embedded
    protobuf
  ] ++ extraPackages;

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  };
}
