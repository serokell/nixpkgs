{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.jackett;

in
{
  options = {
    services.jackett = {
      enable = lib.mkEnableOption "Jackett, API support for your favorite torrent trackers";

      port = lib.mkOption {
        default = 9117;
        type = lib.types.port;
        description = ''
          Port serving the web interface
        '';
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/jackett/.config/Jackett";
        description = "The directory where Jackett stores its data files.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open ports in the firewall for the Jackett web interface.";
      };

      user = lib.mkOption {
        type = lib.types.str;
        default = "jackett";
        description = "User account under which Jackett runs.";
      };

      group = lib.mkOption {
        type = lib.types.str;
        default = "jackett";
        description = "Group under which Jackett runs.";
      };

      package = lib.mkPackageOption pkgs "jackett" { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d '${cfg.dataDir}' 0700 ${cfg.user} ${cfg.group} - -"
    ];

    systemd.services.jackett = {
      description = "Jackett";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        ExecStart = "${cfg.package}/bin/Jackett --NoUpdates --Port ${toString cfg.port} --DataFolder '${cfg.dataDir}'";
        Restart = "on-failure";
      };
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = [ cfg.port ];
    };

    users.users = lib.mkIf (cfg.user == "jackett") {
      jackett = {
        group = cfg.group;
        home = cfg.dataDir;
        uid = config.ids.uids.jackett;
      };
    };

    users.groups = lib.mkIf (cfg.group == "jackett") {
      jackett.gid = config.ids.gids.jackett;
    };
  };
}
