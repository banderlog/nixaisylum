## crush ai coding agent
# Edit freely, then run 'nixaisylum sync' to apply changes.
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ crush ];

  # for custom stuff you will need /workspace/crushrc
  environment.variables = {
    CRUSH_GLOBAL_CONFIG="/workspace";
  };

}
