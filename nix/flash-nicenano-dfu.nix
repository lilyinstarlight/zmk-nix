{ lib
, writeShellApplication
, systemd
, adafruit-nrfutil
, firmware
}:

writeShellApplication {
  name = "zmk-nicenano-dfu-flash";

  runtimeInputs = [
    adafruit-nrfutil
    # udevadm is from systemd
    systemd
  ];

  text = ''
    TTY_PREFIXES=(ttyUSB ttyACM)

    available() {
      shopt -s nullglob
      for prefix in "''${TTY_PREFIXES[@]}"; do
        for tty in /dev/"''${prefix}"*; do
          if [ "$(udevadm info --query=property --property=ID_MODEL --value "$tty")" == "nice_nano_v2" ]; then
            echo "$tty"
            shopt -u nullglob
            return
          fi
        done
      done
      shopt -u nullglob
      return 1
    }

    flash=("$@")
    parts=(${toString firmware.parts or ""})

    if [ "''${#flash[@]}" -eq 0 ]; then
      if [ "''${#parts[@]}" -eq 0 ]; then
        flash=("")
      else
        flash=("''${parts[@]}")
      fi
    else
      for part in "''${flash[@]}"; do
        if ! printf '%s\0' "''${parts[@]}" | grep -Fxqz -- "$part"; then
          echo "The '$part' part does not exist in the firmware '"'${firmware.name}'"'"
          exit 1
        fi
      done
    fi

    cleanup() {
      for p in "''${flash[@]}"; do
        rm -f "''${upgradedir}/''${p}.zip"
      done
      rmdir "''${upgradedir}"
    }
    upgradedir="$(mktemp -d)"
    trap cleanup EXIT

    for part in "''${flash[@]}"; do
      echo -n "Double tap reset and plug in$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB"
      while ! device="$(available)"; do
        echo -n .
        sleep 3
      done
      echo

      adafruit-nrfutil dfu genpkg --dev-type 0x0052 --application ${firmware}/*"$([ -n "$part" ] && echo "_$part")".hex "''${upgradedir}/''${part}.zip"
      adafruit-nrfutil dfu serial --package "''${upgradedir}/''${part}.zip" --port "$device" -b 115200

      echo "Firmware copy complete."

      sleep 1

      echo
    done
  '';

  meta = with lib; {
    description = "ZMK nicenano DFU firmware flasher";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
