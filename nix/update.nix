{ lib
, writeShellApplication
, coreutils
, findutils
, git
, gnugrep
, gnused
, nix
, yq
}:

writeShellApplication {
  name = "zmk-firmware-update";

  runtimeInputs = [
    coreutils
    findutils
    git
    gnugrep
    gnused
    nix
    yq
  ];

  text = ''
    export NIX_CONFIG='extra-experimental-features = nix-command flakes'

    # get repo toplevel
    toplevel="$(git rev-parse --show-toplevel || (printf 'Could not find root of repository\nAre we running from within the git repo?\n' >&2; exit 1))"

    # get package attr and path
    attr="''${UPDATE_NIX_ATTR_PATH:-firmware}"
    westRoot="$toplevel/''${UPDATE_WEST_ROOT:-config}"
    pkgpath="$(nix eval --raw "$toplevel"#"$attr".meta.position | cut -d: -f1)"
    outpath="$(nix eval --raw --impure --expr "builtins.fetchGit { url = \"$toplevel\"; shallow = true; }")"
    [ -n "$outpath" ] && pkgpath="''${pkgpath/$outpath/$toplevel}"

    # get manifest revision heads and update
    # shellcheck disable=SC2016
    yq -cj '
      .manifest.remotes as $remotes
      | .manifest.projects
      | map(.remote as $remote | {name, url: (($remotes[] | select(.name == $remote))."url-base" + "/" + (if ."repo-path" then ."repo-path" else .name end)), revision}) []
      | tostring + "\u0000"
    ' "$westRoot"/west.yml | xargs -0 -L1 "$BASH" -c '
      set -euo pipefail

      westRoot="$0"
      project="$1"

      url="$(echo "$project" | yq -r .url)"
      currevision="$(echo "$project" | yq -r .revision)"
      head="$(grep -F "$currevision" "$westRoot"/west.yml | cut -d"#" -f2 | tr -d " ")"

      [ -z "$head" ] && exit 0

      newrevision="$(git ls-remote "$url" "$head" | sed -e "s/\t.*$//")"
      sed -i -e "s|$currevision|$newrevision|" "$westRoot"/west.yml
    ' "$westRoot"

    # get new deps hash
    curhash="$(nix eval --raw "$toplevel"#"$attr".westDeps.outputHash)"
    drv="$(nix eval --raw "$toplevel"#"$attr".westDeps --apply 'drv: (drv.overrideAttrs { outputHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; }).drvPath')"
    newhash="$(nix build --no-link "$drv^*" 2>&1 >/dev/null | tail -n3 | grep -F got: | cut -d: -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' || true)"

    # set new deps hash
    sed -i -e "s|\"$curhash\"|\"$newhash\"|" "$pkgpath"
  '';

  meta = with lib; {
    description = "ZMK config dependency updater";
    license = licenses.mit;
    platforms = platforms.all;
    maintainers = with maintainers; [ /*lilyinstarlight*/ ];
  };
}
