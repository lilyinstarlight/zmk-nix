{ lib
, writeShellApplication
, firmware
, script-name ? "zmk-uf2-flash"
}:

writeShellApplication {
  name = script-name;

  runtimeInputs = [
  ];

  text = ''
    available() {
      if system_profiler SPUSBDataType 2>/dev/null | grep -Fsq 'nRF UF2'; then
        for device in $(diskutil list | rg -oNI '/dev/[^ ]*'); do
          if diskutil info "$device" | grep -Fsq 'nRF UF2'; then
            diskutil info "$device" | grep -F 'Mount Point:' | cut -d':' -f2 | tr -d '[:space:]'
          fi
        done
      fi
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
      echo -n "Double tap reset and plug in$([ -n "$part" ] && echo " the '$part' part of") the keyboard via USB or press ^C to cancel."
      mountpoint="$(available)"
      while [[ -z "$mountpoint" ]]; do
        echo -n .
        sleep 1
        mountpoint="$(available)"
      done
      echo

      echo -n "Copying firmware to$([ -n "$part" ] && echo " the '$part' part of") the device..."
      # On macOS, the ZMK firmware finishes its "flashing" process before the
      # `cp` command finishes its execution. This is normal, and expected
      # behavior. For us, though, means that this piece of the script will
      # signalize a failure to Nix, since `cp` will exit with code != than `0`.
      # The way we prevent a "command failure", is to indicate to nix that we're
      # handling the error ourselves, which simply indicates that the operation
      # finished successfully.
      if ! cp ${firmware}/*"$([ -n "$part" ] && echo "_$part")".uf2 "$mountpoint/" 2>/dev/null; then
        echo "Done"
      else
        echo "ERROR"
        echo "There was a failure during firmware copy. Your keyboard might still be in 'bootload' mode!"
        exit 1
      fi

      sleep 1

      mountpoint=""
    done
  '';

  meta = with lib; {
    description = "ZMK UF2 firmware flasher";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = with maintainers; [lilyinstarlight];
  };
}
