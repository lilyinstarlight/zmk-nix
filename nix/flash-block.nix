{ lib
, writeShellApplication
, coreutils
, systemd
, util-linux
, findutils
, firmware
}:

writeShellApplication {
  name = "zmk-uf2-block-flash";

  runtimeInputs = [
    coreutils
    findutils
    # udevadm is from systemd
    systemd
    util-linux
  ];

  text = ''
    declare -a uf2devices

    function banner {
      echo "############################################################"
      echo "### $1"
      echo "############################################################"
      echo
    }

    function updateUF2Devices {
      uf2devices=()
      while IFS= read -r device; do
        uf2devices+=("$device")
      done < <(find /dev/mapper -maxdepth 1 -name 'uf2_bootloader_*' -print)
    }

    function sanityCheckBlockDevice {
      # If a user yanks the bootloader at a /very/ particular moment when udev is
      # reloading, it can leave the symlink behind, which could then point to something
      # that is not the UF2 device.  This refuses to run as root, so the actual write
      # should fail, but lets do some sanity checking.
      local blockDevice="$1"
      local maxDeviceSize=$((256 * 1024 * 1024))
      local deviceSize
      local deviceFsType
      deviceSize="$(udevadm info --query=property --property=ID_FS_SIZE --value "$blockDevice")"
      deviceFsType="$(udevadm info --query=property --property=ID_FS_TYPE --value "$blockDevice")"

      if [ "$deviceSize" -gt $maxDeviceSize ]; then
        echo "ERROR: Sanity check of UF2 block device failed, device seems infeasibly"
        echo "large to actually be a microcontroller."
        echo
        echo "Refusing to continue"
        exit 1
      fi

      if [ "$deviceFsType" != "vfat" ]; then
        echo "ERROR: Sanity check of UF2 block device failed, device does not contain"
        echo "a vfat filesystem, which is expected of UF2 bootloaders."
        echo
        echo "Refusing to continue"
        exit 1
      fi
    }

    banner "UF2 Block Flasher"

    if [ "$EUID" -eq 0 ]; then
      echo "This script should not be run as root."
      exit 1
    fi

    updateUF2Devices
    if [ "''${#uf2devices[@]}" -gt 0 ]; then
      banner "Pre-flash warning"
      echo "Found available UF2 devices, if you have not already put your"
      echo "device into bootloader mode, then this may be a different device"
      echo "than expected.  Press <CTRL>+<C> to stop."
      echo
      for device in "''${uf2devices[@]}"; do
        echo " * $device"
      done
      echo
      echo "Waiting for 5 seconds before continuing"
      for _ in $(seq 5); do
        echo -n "."
        sleep 1
      done
      echo
      echo "Continuing"
    fi

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
      banner "Flashing $part"
      echo "Place device into bootloader mode and connect to via USB to begin flashing"
      echo -n "Waiting for device: "
      while :; do
        updateUF2Devices
        case "''${#uf2devices[@]}" in
          0)
            echo -n "."
            sleep 1
            continue
            ;;
          1)
            echo
            flashDevice="''${uf2devices[0]}"
            break
            ;;
          *)
            echo "ERROR: Multiple UF2 devices found, cannot determine which one to flash"
            echo "Flashing terminated, exiting"
            exit 1
            ;;
        esac
      done

      deviceFirmwareFile=(${firmware}/*"$([ -n "$part" ] && echo "_$part")".uf2)
      if [ "''${#deviceFirmwareFile[@]}" -ne 1 ]; then
        echo "Unexpected error, multiple firmware files globbed"
        exit 2
      fi
      sanityCheckBlockDevice "$flashDevice"
      ( set -x ; dd if="''${deviceFirmwareFile[0]}" of="$flashDevice" )

      echo "Firmware copy for $part complete."
      echo

      declare -i deviceResetWait=0
      while :; do
          updateUF2Devices
          if [ "''${#uf2devices[@]}" -eq 0 ]; then
            break
          fi
          case "$deviceResetWait" in
            0 | 1 | 2)
              ;;
            3)
              echo -n "Waiting for device to exit bootloader mode"
              ;;
            *)
              echo -n "."
          esac
          deviceResetWait+=1
          sleep 1
      done
      if [ "$deviceResetWait" -gt 2 ]; then
        echo
      fi

    done

    echo "Flashing complete, terminating"
  '';

  meta = with lib; {
    description = "ZMK UF2 firmware flasher";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}
