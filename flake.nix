# Experimental flake interface to Nixpkgs.
# See https://github.com/NixOS/rfcs/pull/49 for details.
{
  description = "A collection of packages for the Nix package manager";

  outputs = { self }:
    let
      jobs = import ./pkgs/top-level/release.nix {
        nixpkgs = self;
      };

      lib = import ./lib;

      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      lib = lib.extend (final: prev: {

        nixos = import ./nixos/lib { lib = final; };

        nixosSystem = args:
          import ./nixos/lib/eval-config.nix (
            args // {
              modules = args.modules ++ [{
                system.nixos.versionSuffix =
                  ".${final.substring 0 8 (self.lastModifiedDate or self.lastModified or "19700101")}.${self.shortRev or "dirty"}";
                system.nixos.revision = final.mkIf (self ? rev) self.rev;
              }];
            } // lib.optionalAttrs (! args?system) {
              # Allow system to be set modularly in nixpkgs.system.
              # We set it to null, to remove the "legacy" entrypoint's
              # non-hermetic default.
              system = null;
            }
          );
      });

      checks.x86_64-linux.tarball = jobs.tarball;

      htmlDocs = {
        nixpkgsManual = jobs.manual;
        nixosManual = (import ./nixos/release-small.nix {
          nixpkgs = self;
        }).nixos.manual.x86_64-linux;
      };

      # The "legacy" in `legacyPackages` doesn't imply that the packages exposed
      # through this attribute are "legacy" packages. Instead, `legacyPackages`
      # is used here as a substitute attribute name for `packages`. The problem
      # with `packages` is that it makes operations like `nix flake show
      # nixpkgs` unusably slow due to the sheer number of packages the Nix CLI
      # needs to evaluate. But when the Nix CLI sees a `legacyPackages`
      # attribute it displays `omitted` instead of evaluating all packages,
      # which keeps `nix flake show` on Nixpkgs reasonably fast, though less
      # information rich.
      legacyPackages = forAllSystems (system: import ./. { inherit system; });

      nixosModules = {
        notDetected = ./nixos/modules/installer/scan/not-detected.nix;
      };

      apps.x86_64-linux = let
        pkgs = self.legacyPackages.x86_64-linux;
      in {
        repin = {
          type = "app";
          program = builtins.toString (pkgs.writers.writeBash "repin" ''
            set -eu pipefail

            : ''${REMOTE_BRANCH:="nixos-unstable-small"}
            : ''${MERGE_BRANCH:="repin"}

            CUR_BRANCH=$(git branch | grep "*" | cut -d " " -f 2)
            REMOTE_REPO=$(${pkgs.openssl}/bin/openssl rand -base64 12)

            cleanup() {
              git remote remove "$REMOTE_REPO" 2>/dev/null
              git checkout "$CUR_BRANCH"
            }

            trap cleanup SIGINT

            git checkout master
            git remote add "$REMOTE_REPO" git@github.com:nixos/nixpkgs
            git fetch "$REMOTE_REPO"

            git checkout -b "$MERGE_BRANCH"

            # in a rebase, ours/theirs are swapped, see `git rebase --help`
            git rebase "$REMOTE_REPO"/"$REMOTE_BRANCH" -X theirs

            git remote remove "$REMOTE_REPO"
          '');
        };
      };
    };
}
