{ lib, stdenv }:

stdenv.mkDerivation rec {
  pname = "uf2-udev-rules";
  version = "20240627";

  src = [ ./uf2-block.rules ];

  dontUnpack = true;

  installPhase = ''
    install -Dpm644 $src $out/lib/udev/rules.d/99-uf2-block.rules
  '';

  meta = with lib; {
    description = "udev rules that give all users permission to write to UF2 bootloader block devices";
    platforms = platforms.linux;
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
