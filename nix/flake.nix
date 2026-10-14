# Flake for building VMs via nixaisylum.sh
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, microvm, ... }:
  let
    readValue = path: nixpkgs.lib.trim (builtins.readFile path);
    projectRoot = readValue ./project-root;
    system = readValue ./system;
    sshPort = nixpkgs.lib.toInt (readValue ./ssh-port);
  in
  {
    nixosConfigurations.vm = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        microvm.nixosModules.microvm
        # VM nix config from ./templates/
        ./nixaisylum.vm.nix

        # VM base config
        (
          { pkgs, lib, ... }:
          {
            networking.hostName = "nixaisylum";
            # mkDefault: overridable from nixaisylum.vm.nix, opt-in by the user
            networking.firewall.enable = lib.mkDefault false;
            system.stateVersion = "26.05";

            systemd.network.enable = true;
            systemd.network.networks."10-lan" = {
              matchConfig.Name = "*";
              networkConfig.DHCP = "yes";
            };

            services.getty.autologinUser = "user";
            services.openssh = {
              enable = true;
              hostKeys = [{
                path = "/etc/ssh/host-keys/ssh_host_ed25519_key";
                type = "ed25519";
              }];
              settings.PasswordAuthentication = false;
            };

            users.users.user = {
              isNormalUser = true;
              extraGroups = [ "wheel" ];
              shell = pkgs.bashInteractive;
              openssh.authorizedKeys.keyFiles = [ ./id_ed25519.pub ];
            };
            security.sudo.wheelNeedsPassword = false;

            microvm = {
              hypervisor = "qemu";

              # mkDefault: overridable from nixaisylum.vm.nix
              mem = lib.mkDefault 4096;
              vcpu = lib.mkDefault 4;

              interfaces = [{
                type = "user";
                id = "net0";
                mac = "02:00:00:00:00:01";
              }];
              forwardPorts = [{
                from = "host";
                host.port = sshPort;
                guest.port = 22;
              }];

              # Default --socket-group=kvm fails unless the user is in that group
              virtiofsd.group = null;

              # Sockets keep upstream's relative default names on purpose
              shares = [
                {
                  proto = "virtiofs";
                  tag = "workspace";
                  source = projectRoot;
                  mountPoint = "/workspace";
                }
                {
                  proto = "virtiofs";
                  tag = "ssh-host-keys";
                  source = "${projectRoot}/.nixaisylum-vm/ssh-host-keys";
                  mountPoint = "/etc/ssh/host-keys";
                  readOnly = true;
                }
              ];
            };
          }
        )
      ];
    };
  };
}
