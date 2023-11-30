{ lib
, writeShellApplication
, util-linux
, firmware
}:

writeShellApplication {
  name = "flash";

  runtimeInputs = [
    util-linux
  ];

  text = ''
    available() {
      lsblk -Sno path,model | grep -F TODO | cut -d' ' -f1
    }

    mounted() {
      findmnt "$device" -no target
    }

    # shellcheck disable=SC2043
    for part in ${toString firmware.parts or ''""''}; do
      echo -n "Double tap reset and plug in$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB"
      while ! device="$(available)"; do
        echo -n .
        sleep 3
      done
      echo

      sleep 1

      mountpoint="$(mounted)"
      if [ -z "$mountpoint" ]; then
        echo -n "Please mount the mass storage device at $device so that the firmware file can be copied"
        while ! mountpoint="$(mounted)"; do
          echo -n .
          sleep 3
        done
      fi
      echo

      cp ${firmware}/*"$([ -n "$part" ] && ehco "_$part")".uf2
    done
  '';

  meta = with lib; {
    description = "Keyboard ZMK firmware flasher";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ lilyinstarlight ];
  };
}
