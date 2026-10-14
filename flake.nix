# Wrapper to run nixaisylum.sh remotely via nix flake
{
  description = "Project-local NixOS MicroVM environments";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in
  {
    packages = forAllSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixaisylum = pkgs.writeShellApplication {
          name = "nixaisylum";
          runtimeInputs = with pkgs; [
            coreutils
            gnugrep
            nix
            openssh
          ];
          text = builtins.replaceStrings
            [ "@NIXAISYLUM_NIX_DIR@" "@NIXAISYLUM_VERSION@" ]
            [ "${./nix}" "0.2.0" ]
            (builtins.readFile ./nixaisylum.sh);
        };
      in {
        default = nixaisylum;
        inherit nixaisylum;
      });

    apps = forAllSystems (system: {
      default = {
        type = "app";
        program = "${self.packages.${system}.default}/bin/nixaisylum";
      };
    });

    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
  };
}
