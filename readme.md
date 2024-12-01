# zmk-nix

Build system and configuration files for generating and building ZMK firmware

I've included my personal configuration for my Sofle RGB in this repository, but the Nix flake provides generalized builders that can be used from downstream flakes.


## Usage

### Nix Flakes

Use the default flake template to create a fully working downstream repository that uses the zmk-nix flake to build your own ZMK config.

```sh
$ mkdir zmk-config && cd zmk-config
$ git init
$ nix flake init --template github:lilyinstarlight/zmk-nix
$ nix flake lock
$ git add .
```

Follow the welcome text below that is printed when initializing from the template for using this new repository:

> #### Getting started
> 
> - Change `buildSplitKeyboard` to `buildKeyboard` in `flake.nix` if not using a split keyboard
> - Edit for the desired ZMK board and shield(s) in `flake.nix`
> - Create and edit `config/<shield>.conf` and `config/<shield>.keymap` to your liking
> - Run `nix run .#flash` to flash firmware
> 
> 
> #### Maintenance
> 
> - Run `nix run .#update` to update West dependencies, including ZMK version, and bump the `zephyrDepsHash` on the derivation
> - GitHub Actions to automatically PR flake lockfile bumps and West dependency bumps are included
> - Using something like Mergify to automatically merge these PRs is recommended - see <https://github.com/lilyinstarlight/zmk-nix/blob/main/.github/mergify.yml> for an example Mergify configuration


## Builders

### `fetchZephyrDeps`

The `fetchZephyrDeps` function takes the following arguments and fetches the dependencies required for the provided `west` workspace:

* `src` - source tree to build in, which includes your west manifest
* `hash` - fixed-output hash for the west dependencies
* `westRoot` - directory within the source tree that contains your west manifest, defaults to `"."`


### `buildZephyrPackage`

The `buildZephyrPackage` function takes the following arguments and builds the Zephyr RTOS into `.uf2` firmware files using the `west` tooling and a provided `west.yml` manifest:

* `src` - source tree to build in, which includes your west manifest
* `zephyrDepsHash` - output hash for the `fetchZephyrDeps` fetcher
* `westRoot` - directory within the source tree that contains your west manifest, defaults to `"."`
* `westBuildFlags` - flags to pass to the `west build` command, defaults to `[]` (a `-DBUILD_VERSION=` CMake flag also gets automatically added by default for Zephyr-based builds)


### `buildKeyboard`

The `buildKeyboard` function takes the following arguments and performs a ZMK build that outputs a `zmk.uf2` file based on the provided parameters:

* `board` - ZMK board value
* `shield` - ZMK shield value
* `src` - source tree to build in, which includes your west manifest and configuration files
* `zephyrDepsHash` - output hash for the `fetchZephyrDeps` fetcher
* `config` - directory within the source tree that contains your west manifest, defaults to `"config"`
* `enableZmkStudio` - automatically pass in necessary ZMK `west build` flags and add dependencies for building ZMK Studio support
* `extraWestBuildFlags` - list of extra flags to pass to the ZMK `west build` command, defaults to `[]` (should not include `--` or subsequent CMake flags)
* `extraCmakeFlags` - list of extra CMake flags to pass to the ZMK build, defaults to `[]`


### `buildSplitKeyboard`

The `buildSplitKeyboard` function takes the following arguments and outputs a directory with multiple `.uf2` files, one for each keyboard part:

* `board` - ZMK board value
* `shield` - ZMK shield value, the special string `%PART%` will be replaced in each `buildKeyboard` invocation to match the part being built for
* `parts` - enumeration of parts to the keyboard that matches the shield naming, default is `[ "left" "right" ]`
* `src` - source tree to build in, which includes your west manifest and configuration files
* `zephyrDepsHash` - output hash for the `fetchZephyrDeps` fetcher
* `config` - directory within the source tree that contains your west manifest, defaults to `"config"`
* `enableZmkStudio` - automatically pass in necessary ZMK `west build` flags and add dependencies for building ZMK Studio support
* `extraWestBuildFlags` - list of extra flags to pass to the ZMK `west build` command, defaults to `[]` (should not include `--` or subsequent CMake flags)
* `extraCmakeFlags` - list of extra CMake flags to pass to the ZMK build, defaults to `[]`


## Flashers

All flashers take the following arguments.

* `firmware` - Derivation of one of the *builders*.

### `flash` (default)

The `flash` function flashes nRF devices that use an Adafruit bootloader.
After placing the device into bootloader mode the user is required to mount the vfat filesystem in a manner the user running the flash script is allowed to copy a file to the device.

### `flashBlock`

The `flashBlock` function flashes UF2 bootloaders by directly writing the new firmware to the UF2 to the block device.
This requires no user interaction after initial UDEV setup, and prevents a mounted filesystem from disappearing.
This requires a *UDEV Rule*, which can be included in nixos by adding the `zmk-nix.nixosModules.udevRules` to the nixosSystem modules.
On non-nixos systems, [uf2-block.rules](./nix/uf2-udev-rules/uf2-block.rules) to `/etc/udev/rules.d`.
The udev rule currently supports:

* Adafruit nRF UF2 bootloaders
* RP2 bootloaders (RP2040)


## Packages

### `firmware`

My Sofle RGB's firmware, built with the configuration I have in this repository.


### `flash`

A flashing script that automatically handles prompting and copying `.uf2` firmware files to the controllers.


### `update`

A updater script that automatically bumps West dependencies and bumps the `zephyrDepsHash` value for the `.#firmware` derivation in the current directory.
