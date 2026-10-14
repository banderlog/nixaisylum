## docker daemon
# net via --host
# run containers via -u 0
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ docker ];

  virtualisation.docker = {
    enable = true;
  };

}
