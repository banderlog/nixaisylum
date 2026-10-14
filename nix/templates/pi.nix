## pi ai coding agent
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ pi-coding-agent ];

  # for custom stuff you will need /workspace/.pi/models.json
  environment.variables = {
    PI_CODING_AGENT_DIR="/workspace/.pi";
  };
}
