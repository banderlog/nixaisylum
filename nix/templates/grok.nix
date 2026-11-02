## grok build AI coding agent
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ grok-build ];

  # Grok Build looks here for config.toml, auth tokens, and logs
  environment.variables = {
    GROK_HOME = "/workspace/.grok";
    GROK_TELEMETRY_ENABLED="false";
    GROK_TELEMETRY_TRACE_UPLOAD="false";
  };

  # Run after the virtiofs mount for /workspace is ready
  systemd.services.init-grok-home = {
    description = "Create /workspace/.grok directory";
    wantedBy = [ "multi-user.target" ];
    after = [ "workspace.mount" "local-fs.target" ];
    requires = [ "workspace.mount" ]; # Only if /workspace is in microvm.shares
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/mkdir -p /workspace/.grok";
      RemainAfterExit = true;
    };
  };
}
