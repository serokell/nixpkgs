import ./make-test-python.nix (
  { lib, ... }:
  {
    name = "earlyoom";
    meta = {
      maintainers = with lib.maintainers; [
        ncfavier
        AndersonTorres
      ];
    };

    machine = {
      services.earlyoom = {
        enable = true;
      };
    };

    testScript = ''
      machine.wait_for_unit("earlyoom.service")
    '';
  }
)
