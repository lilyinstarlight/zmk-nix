{ lib
, stdenv
, cacert
, git
, python3
, writers
, yq
}:

let
  west = python3.withPackages (ps: [ ps.west ps.pyelftools ]);
in

{
  name ? "zephyr-deps",
  hash ? "",
  westRoot ? ".",
  ...
} @ args: let
  hash_ = if hash != "" then {
    outputHash = hash;
  } else {
    outputHash = "";
    outputHashAlgo = "sha256";
  };

  make-fake-west-git = writers.writePython3Bin "make-fake-west-git" {} ''
    import hashlib
    import os
    import os.path
    import shutil
    import zlib


    def walk_breadth(path):
        return sorted(os.walk(path, topdown=False),
                      key=(lambda walkdir: walkdir[0].count(os.path.sep)),
                      reverse=True)


    def init_repo(git_dir):
        os.makedirs(os.path.join(git_dir, 'refs/heads'), exist_ok=True)
        os.makedirs(os.path.join(git_dir, 'objects'), exist_ok=True)


    def write_object(git_dir, object_type, contents):
        object_raw = object_type.encode() + b' ' + \
                     str(len(contents)).encode() + b'\x00' + contents
        object_hash = hashlib.sha1(object_raw).hexdigest()

        object_path = os.path.join(git_dir,
                                   'objects', object_hash[:2], object_hash[2:])

        os.makedirs(os.path.dirname(object_path), exist_ok=True)

        with open(object_path, 'wb') as object_file:
            object_file.write(zlib.compress(object_raw, 0))

        return object_hash


    def write_single_file_tree(git_dir, file_path, base_path):
        tree_file = file_path.removeprefix(base_path).removeprefix('/')

        tree = None
        for part in sorted(tree_file.split(os.path.sep), reverse=True):
            if tree:
                contents = b'40000 ' + part.encode() + b'\x00' + \
                           bytes.fromhex(tree)
            else:
                with open(file_path, 'rb') as single_file:
                    file_object = write_object(git_dir, 'blob', single_file.read())
                contents = b'100644 ' + part.encode() + b'\x00' + \
                           bytes.fromhex(file_object)

            tree = write_object(git_dir, 'tree', contents)

        return tree


    def write_commit(git_dir, git_tree):
        contents = b'tree ' + git_tree.encode() + \
                   b'\nauthor . <.> 0 +0000\ncommitter . <.> 0 +0000\n\n'

        return write_object(git_dir, 'commit', contents)


    if __name__ == '__main__':
        import sys
        import tempfile

        real_git = sys.argv[1]
        real_repo = os.path.dirname(real_git)
        fake_git = tempfile.mkdtemp()

        if os.path.isdir(real_git):
            init_repo(fake_git)

            try:
                west_yml = os.path.join(next(dirpath for (dirpath, _, filenames) in
                                        walk_breadth(real_repo)
                                        if 'west.yml' in filenames), 'west.yml')

                west_tree = write_single_file_tree(fake_git, west_yml, real_repo)
                west_commit = write_commit(fake_git, west_tree)

                with open(os.path.join(fake_git,
                                       'refs/heads/manifest-rev'), 'wb') as head:
                    head.write(west_commit.encode() + b'\n')
            except StopIteration:
                shutil.copyfile(os.path.join(real_git, 'refs/heads/manifest-rev'),
                                os.path.join(fake_git, 'refs/heads/manifest-rev'))

            shutil.copyfile(os.path.join(real_git, 'HEAD'),
                            os.path.join(fake_git, 'HEAD'))

            shutil.rmtree(real_git)
            shutil.move(fake_git, real_git)
        else:
            os.remove(real_git)
  '';
in stdenv.mkDerivation ((lib.removeAttrs args [ "hash" ]) // {
  inherit name westRoot;

  nativeBuildInputs = [
    make-fake-west-git
    git
    west
    yq
  ];

  env.GIT_SSL_CAINFO = "${cacert}/etc/ssl/certs/ca-bundle.crt";

  dontFixup = true;

  configurePhase = ''
    runHook preConfigure

    mkdir -p .west
    cat >.west/config <<EOF
    [manifest]
    path = $westRoot
    file = west.yml
    EOF

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    west update

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir $out
    west list -f '- {{name: {name!r}, path: {path!r}}}' | yq -j '
      map(select(.name != "manifest")
      | .path
      | split("/")[0])
      | unique [] + "\u0000"
    ' | xargs -0 mv -t $out --

    find $out -name .git -print0 | xargs -0 -n1 make-fake-west-git

    runHook postInstall
  '';

  outputHashMode = "recursive";
} // hash_)
