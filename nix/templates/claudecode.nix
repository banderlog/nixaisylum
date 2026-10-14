## claudecode ai coding agent
{ pkgs, ... }:
let
  claude_with_env = pkgs.writeShellScriptBin "claude_with_env" ''
    export DISABLE_TELEMETRY=1
    export DISABLE_ERROR_REPORTING=1
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
    export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
    export CLAUDE_CODE_MAX_OUTPUT_TOKENS=128000
    export ENABLE_TOOL_SEARCH=false
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS=1
    export ANTHROPIC_BASE_URL=http://10.0.2.2:1080
    export ANTHROPIC_API_KEY="any-value"
    exec claude "$@"
  '';
in
{
  nixpkgs.config.allowUnfree = true;

  ## Add project-specific packages
  environment.systemPackages = with pkgs; [
    claude-code
    claude_with_env
    vim
    jq
    git
    #nodejs_24
  ];

  environment.localBinInPath = true;

  environment.variables = {
    EDITOR = "vim";
    # keeps everuthing local
    CLAUDE_CONFIG_DIR = "/workspace/.claude";
  };

  # VM resources, firewall, ports and shares belong in nixaisylum.vm.nix
}
