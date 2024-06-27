{ mkShell
, cmake
, ninja
, gcc-arm-embedded
, python3
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
    ]))
    gcc-arm-embedded
  ];

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  };
}
