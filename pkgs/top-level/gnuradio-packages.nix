{
  lib,
  stdenv,
  newScope,
  gnuradio, # unwrapped gnuradio
}:

lib.makeScope newScope (
  self:

  let
    # Modeled after qt's
    mkDerivationWith = import ../development/gnuradio-modules/mkDerivation.nix {
      inherit lib;
      unwrapped = gnuradio;
    };
    mkDerivation = mkDerivationWith stdenv.mkDerivation;

    callPackage = self.newScope (
      {
        inherit (gnuradio)
          # Packages that are potentially overridden and used as deps here.
          boost
          volk
          logLib
          python
          qwt
          ;
        inherit mkDerivationWith mkDerivation;
        inherit gnuradio;
        inherit (gnuradio) gnuradioOlder gnuradioAtLeast;
      }
      // lib.optionalAttrs (gnuradio.hasFeature "gr-uhd") {
        inherit (gnuradio) uhd;
      }
    );
  in
  {

    inherit callPackage mkDerivation mkDerivationWith;

    ### Packages

    osmosdr = callPackage ../development/gnuradio-modules/osmosdr/default.nix { };

    ais = callPackage ../development/gnuradio-modules/ais/default.nix { };

    grnet = callPackage ../development/gnuradio-modules/grnet/default.nix { };

    gsm = callPackage ../development/gnuradio-modules/gsm/default.nix { };

    nacl = callPackage ../development/gnuradio-modules/nacl/default.nix { };

    rds = callPackage ../development/gnuradio-modules/rds/default.nix { };

    limesdr = callPackage ../development/gnuradio-modules/limesdr/default.nix { };

  }
)
