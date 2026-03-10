{ lib
, writeShellApplication
, util-linux
, firmware
}:

writeShellApplication {
  name = "zmk-uf2-flash";

  runtimeInputs = [
    util-linux
  ];

  text = ''
    available() {
      lsblk -Sno path,model | grep -F 'nRF UF2' | cut -d' ' -f1
    }

    mounted() {
      findmnt "$device" -no target
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

    for part in "''${flash[@]}"; do
      echo -n "Double tap reset and plug in$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB"
      while ! device="$(available)"; do
        echo -n .
        sleep 3
      done
      echo
      echo "Found device at $device"

      # Try to mount via udisks. If it works, we're good and the mountpoint
      # should be found in the next step. If not, it's either been auto-mounted
      # before we could which would also work out fine or it cannot be mounted
      # by udisks which would require the user to intervene manually in any
      # case.
      udisks_error="$(udisksctl mount --block-device "$device" 2>&1 || true)"

      if ! mountpoint="$(mounted)"; then
        echo "The device could not be mounted automatically. Running \`udisksctl mount\` produced the following error:"
        echo "$udisks_error"
        echo
        echo -n "Please mount the mass storage device at $device so that the firmware file can be copied"
        while ! mountpoint="$(mounted)"; do
          echo -n .
          sleep 3
        done
        echo
      fi
      echo "Found mountpoint at $mountpoint"

      cp ${firmware}/*"$([ -n "$part" ] && echo "_$part")".uf2 "$mountpoint"

      echo "Firmware copy complete."

      sleep 1

      if mounted >/dev/null && available >/dev/null; then
        echo -n "Please unmount the mass storage device at $device and disconnect$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB"
        while mounted >/dev/null && available >/dev/null; do
          echo -n .
          sleep 3
        done
      fi
      echo
    done
  '';

  meta = with lib; {
    description = "ZMK UF2 firmware flasher";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ /*lilyinstarlight*/ ];
  };
}
