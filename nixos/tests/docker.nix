# This test runs docker and checks if simple container starts

import ./make-test-python.nix ({ pkgs, ...} : {
  name = "docker";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ nequissimus offline ];
  };

  nodes = {
    docker =
      { pkgs, ... }:
        {
          virtualisation.docker = {
            enable = true;
            package = pkgs.docker;
            volumes = [ "thevolume" ];
            networks.thenetwork = {
              driver = "bridge";
              subnet = "172.28.0.0/16";
              ip-range = "172.28.5.0/24";
              gateway = "172.28.5.254";
            };

            logLevel = "warn";
          };

          users.users = {
            noprivs = {
              isNormalUser = true;
              description = "Can't access the docker daemon";
              password = "foobar";
            };

            hasprivs = {
              isNormalUser = true;
              description = "Can access the docker daemon";
              password = "foobar";
              extraGroups = [ "docker" ];
            };
          };
        };
    };

  testScript = ''
    start_all()

    docker.wait_for_unit("sockets.target")
    docker.succeed("tar cv --files-from /dev/null | docker import - scratchimg")
    docker.succeed(
        "docker run -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10"
    )
    docker.succeed("docker ps | grep sleeping")
    docker.succeed("sudo -u hasprivs docker ps")
    docker.fail("sudo -u noprivs docker ps")
    docker.succeed("docker stop sleeping")

    $docker->succeed("docker volume ls | grep thevolume");
    $docker->succeed("docker network ls | grep thenetwork");

    $docker->succeed("docker volume create superfluousvolume");
    $docker->succeed("docker network create superfluousnetwork");
    $docker->systemctl("restart docker");
    $docker->waitForUnit("docker.service");
    $docker->fail("docker volume ls | grep superfluous");

    # Must match version 4 times to ensure client and server git commits and versions are correct
    docker.succeed('[ $(docker version | grep ${pkgs.docker.version} | wc -l) = "4" ]')
  '';
})
