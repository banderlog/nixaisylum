## codex ai coding agent
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ codex ];

  # for custom stuff you will need /workspace/.codex/config.toml
  environment.variables = {
    CODEX_HOME = "/workspace/.codex";
  };

  # Run after the virtiofs mount for /workspace is ready
  systemd.services.init-codex-home = {
    description = "Create /workspace/.codex directory";
    wantedBy = [ "multi-user.target" ];
    after = [ "workspace.mount" "local-fs.target" ];
    requires = [ "workspace.mount" ]; # Only if /workspace is in microvm.shares
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/mkdir -p /workspace/.codex";
      RemainAfterExit = true;
    };
  };
}
