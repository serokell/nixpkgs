{ callPackage, fetchurl, ... } @ args:

callPackage ./generic.nix args {
  version = "1.26.2";
  hash = "sha256-Yn/ghiCbuoCihToK3Z2VjX673/oahGeleEyaa08D1zg=";
  extraPatches = [
    # A part of https://github.com/zlib-ng/patches/tree/master/nginx#1262-zlib-ngpatch
    # that increases the size of pre-allocated memory to fit with zlib-ng requirements
    # to avoid spamming logs with 'gzip filter failed to use preallocated memory' error
    ./nix-zlib-ng-gzip-buffer-1.26.2.patch
  ];
}
