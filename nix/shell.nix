{ mkShell
, cmake
, ninja
, gcc-arm-embedded
, python3
}:

mkShell {
  packages = [
    cmake ninja
    (python3.withPackages (ps: [ ps.west ps.pyelftools ]))
    gcc-arm-embedded
  ];

  env = {
    ZEPHYR_TOOLCHAIN_VARIANT = "gnuarmemb";
    GNUARMEMB_TOOLCHAIN_PATH = gcc-arm-embedded;
  };
}
