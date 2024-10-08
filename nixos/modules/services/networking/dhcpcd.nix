{ config, lib, pkgs, ... }:
let

  dhcpcd = if !config.boot.isContainer then pkgs.dhcpcd else pkgs.dhcpcd.override { udev = null; };

  cfg = config.networking.dhcpcd;

  interfaces = lib.attrValues config.networking.interfaces;

  enableDHCP = config.networking.dhcpcd.enable &&
        (config.networking.useDHCP || lib.any (i: i.useDHCP == true) interfaces);

  enableNTPService = (config.services.ntp.enable || config.services.ntpd-rs.enable || config.services.openntpd.enable || config.services.chrony.enable);

  # Don't start dhcpcd on explicitly configured interfaces or on
  # interfaces that are part of a bridge, bond or sit device.
  ignoredInterfaces =
    map (i: i.name) (lib.filter (i: if i.useDHCP != null then !i.useDHCP else i.ipv4.addresses != [ ]) interfaces)
    ++ lib.mapAttrsToList (i: _: i) config.networking.sits
    ++ lib.concatLists (lib.attrValues (lib.mapAttrs (n: v: v.interfaces) config.networking.bridges))
    ++ lib.flatten (lib.concatMap (i: lib.attrNames (lib.filterAttrs (_: config: config.type != "internal") i.interfaces)) (lib.attrValues config.networking.vswitches))
    ++ lib.concatLists (lib.attrValues (lib.mapAttrs (n: v: v.interfaces) config.networking.bonds))
    ++ config.networking.dhcpcd.denyInterfaces;

  arrayAppendOrNull = a1: a2: if a1 == null && a2 == null then null
    else if a1 == null then a2 else if a2 == null then a1
      else a1 ++ a2;

  # If dhcp is disabled but explicit interfaces are enabled,
  # we need to provide dhcp just for those interfaces.
  allowInterfaces = arrayAppendOrNull cfg.allowInterfaces
    (if !config.networking.useDHCP && enableDHCP then
      map (i: i.name) (lib.filter (i: i.useDHCP == true) interfaces) else null);

  staticIPv6Addresses = map (i: i.name) (lib.filter (i: i.ipv6.addresses != [ ]) interfaces);

  noIPv6rs = lib.concatStringsSep "\n" (map (name: ''
    interface ${name}
    noipv6rs
  '') staticIPv6Addresses);

  # Config file adapted from the one that ships with dhcpcd.
  dhcpcdConf = pkgs.writeText "dhcpcd.conf"
    ''
      # Inform the DHCP server of our hostname for DDNS.
      hostname

      # A list of options to request from the DHCP server.
      option domain_name_servers, domain_name, domain_search, host_name
      option classless_static_routes, ntp_servers, interface_mtu

      # A ServerID is required by RFC2131.
      # Commented out because of many non-compliant DHCP servers in the wild :(
      #require dhcp_server_identifier

      # A hook script is provided to lookup the hostname if not set by
      # the DHCP server, but it should not be run by default.
      nohook lookup-hostname

      # Ignore peth* devices; on Xen, they're renamed physical
      # Ethernet cards used for bridging.  Likewise for vif* and tap*
      # (Xen) and virbr* and vnet* (libvirt).
      denyinterfaces ${toString ignoredInterfaces} lo peth* vif* tap* tun* virbr* vnet* vboxnet* sit*

      # Use the list of allowed interfaces if specified
      ${lib.optionalString (allowInterfaces != null) "allowinterfaces ${toString allowInterfaces}"}

      # Immediately fork to background if specified, otherwise wait for IP address to be assigned
      ${{
        background = "background";
        any = "waitip";
        ipv4 = "waitip 4";
        ipv6 = "waitip 6";
        both = "waitip 4\nwaitip 6";
        if-carrier-up = "";
      }.${cfg.wait}}

      ${lib.optionalString (config.networking.enableIPv6 == false) ''
        # Don't solicit or accept IPv6 Router Advertisements and DHCPv6 if disabled IPv6
        noipv6
      ''}

      ${lib.optionalString (config.networking.enableIPv6 && cfg.IPv6rs == null && staticIPv6Addresses != [ ]) noIPv6rs}
      ${lib.optionalString (config.networking.enableIPv6 && cfg.IPv6rs == false) ''
        noipv6rs
      ''}

      ${cfg.extraConfig}
    '';

  exitHook = pkgs.writeText "dhcpcd.exit-hook" ''
    ${lib.optionalString enableNTPService ''
      if [ "$reason" = BOUND -o "$reason" = REBOOT ]; then
        # Restart ntpd. We need to restart it to make sure that it will actually do something:
        # if ntpd cannot resolve the server hostnames in its config file, then it will never do
        # anything ever again ("couldn't resolve ..., giving up on it"), so we silently lose
        # time synchronisation. This also applies to openntpd.
        ${lib.optionalString config.services.ntp.enable "/run/current-system/systemd/bin/systemctl try-reload-or-restart ntpd.service || true"}
        ${lib.optionalString config.services.ntpd-rs.enable "/run/current-system/systemd/bin/systemctl try-reload-or-restart ntpd-rs.service || true"}
        ${lib.optionalString config.services.openntpd.enable "/run/current-system/systemd/bin/systemctl try-reload-or-restart openntpd.service || true"}
        ${lib.optionalString config.services.chrony.enable "/run/current-system/systemd/bin/systemctl try-reload-or-restart chronyd.service || true"}
      fi
    ''}

    ${cfg.runHook}
  '';

in

{

  ###### interface

  options = {

    networking.dhcpcd.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to enable dhcpcd for device configuration. This is mainly to
        explicitly disable dhcpcd (for example when using networkd).
      '';
    };

    networking.dhcpcd.persistent = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
          Whenever to leave interfaces configured on dhcpcd daemon
          shutdown. Set to true if you have your root or store mounted
          over the network or this machine accepts SSH connections
          through DHCP interfaces and clients should be notified when
          it shuts down.
      '';
    };

    networking.dhcpcd.denyInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
         Disable the DHCP client for any interface whose name matches
         any of the shell glob patterns in this list. The purpose of
         this option is to blacklist virtual interfaces such as those
         created by Xen, libvirt, LXC, etc.
      '';
    };

    networking.dhcpcd.allowInterfaces = lib.mkOption {
      type = lib.types.nullOr (lib.types.listOf lib.types.str);
      default = null;
      description = ''
         Enable the DHCP client for any interface whose name matches
         any of the shell glob patterns in this list. Any interface not
         explicitly matched by this pattern will be denied. This pattern only
         applies when non-null.
      '';
    };

    networking.dhcpcd.extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
         Literal string to append to the config file generated for dhcpcd.
      '';
    };

    networking.dhcpcd.IPv6rs = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Force enable or disable solicitation and receipt of IPv6 Router Advertisements.
        This is required, for example, when using a static unique local IPv6 address (ULA)
        and global IPv6 address auto-configuration with SLAAC.
      '';
    };

    networking.dhcpcd.runHook = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = "if [[ $reason =~ BOUND ]]; then echo $interface: Routers are $new_routers - were $old_routers; fi";
      description = ''
         Shell code that will be run after all other hooks. See
         `man dhcpcd-run-hooks` for details on what is possible.
      '';
    };

    networking.dhcpcd.wait = lib.mkOption {
      type = lib.types.enum [ "background" "any" "ipv4" "ipv6" "both" "if-carrier-up" ];
      default = "any";
      description = ''
        This option specifies when the dhcpcd service will fork to background.
        If set to "background", dhcpcd will fork to background immediately.
        If set to "ipv4" or "ipv6", dhcpcd will wait for the corresponding IP
        address to be assigned. If set to "any", dhcpcd will wait for any type
        (IPv4 or IPv6) to be assigned. If set to "both", dhcpcd will wait for
        both an IPv4 and an IPv6 address before forking.
        The option "if-carrier-up" is equivalent to "any" if either ethernet
        is plugged nor WiFi is powered, and to "background" otherwise.
      '';
    };

  };


  ###### implementation

  config = lib.mkIf enableDHCP {

    assertions = [ {
      # dhcpcd doesn't start properly with malloc ∉ [ libc scudo ]
      # see https://github.com/NixOS/nixpkgs/issues/151696
      assertion =
        dhcpcd.enablePrivSep
          -> lib.elem config.environment.memoryAllocator.provider [ "libc" "scudo" ];
      message = ''
        dhcpcd with privilege separation is incompatible with chosen system malloc.
          Currently only the `libc` and `scudo` allocators are known to work.
          To disable dhcpcd's privilege separation, overlay Nixpkgs and override dhcpcd
          to set `enablePrivSep = false`.
      '';
    } ];

    environment.etc."dhcpcd.conf".source = dhcpcdConf;

    systemd.services.dhcpcd = let
      cfgN = config.networking;
      hasDefaultGatewaySet = (cfgN.defaultGateway != null && cfgN.defaultGateway.address != "")
                          && (!cfgN.enableIPv6 || (cfgN.defaultGateway6 != null && cfgN.defaultGateway6.address != ""));
    in
      { description = "DHCP Client";

        wantedBy = [ "multi-user.target" ] ++ lib.optional (!hasDefaultGatewaySet) "network-online.target";
        wants = [ "network.target" ];
        before = [ "network-online.target" ];

        restartTriggers = lib.optional (enableNTPService || cfg.runHook != "") [ exitHook ];

        # Stopping dhcpcd during a reconfiguration is undesirable
        # because it brings down the network interfaces configured by
        # dhcpcd.  So do a "systemctl restart" instead.
        stopIfChanged = false;

        path = [ dhcpcd pkgs.nettools config.networking.resolvconf.package ];

        unitConfig.ConditionCapability = "CAP_NET_ADMIN";

        serviceConfig =
          { Type = "forking";
            PIDFile = "/run/dhcpcd/pid";
            RuntimeDirectory = "dhcpcd";
            ExecStart = "@${dhcpcd}/sbin/dhcpcd dhcpcd --quiet ${lib.optionalString cfg.persistent "--persistent"} --config ${dhcpcdConf}";
            ExecReload = "${dhcpcd}/sbin/dhcpcd --rebind";
            Restart = "always";
          };
      };

    users.users.dhcpcd = {
      isSystemUser = true;
      group = "dhcpcd";
    };
    users.groups.dhcpcd = {};

    environment.systemPackages = [ dhcpcd ];

    environment.etc."dhcpcd.exit-hook" = lib.mkIf (enableNTPService || cfg.runHook != "") {
      source = exitHook;
    };

    powerManagement.resumeCommands = lib.mkIf config.systemd.services.dhcpcd.enable
      ''
        # Tell dhcpcd to rebind its interfaces if it's running.
        /run/current-system/systemd/bin/systemctl reload dhcpcd.service
      '';

  };

}
