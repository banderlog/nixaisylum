## opencode ai coding agent
{ pkgs, ... }:
let
  # Isolate configs, data, caches, and logs entirely to workspace
  #  all other stuff should be in opencode.json or something like that
  opencode_with_env = pkgs.writeShellScriptBin "opencode_with_env" ''
    export OPENCODE_CONFIG_DIR="/workspace/.opencode/config"
    export OPENCODE_DATA_DIR="/workspace/.opencode/data"
    export OPENCODE_CACHE_DIR="/workspace/.opencode/cache"
    export OPENCODE_LOG_DIR="/workspace/.opencode/log"
    export OPENCODE_STATE_DIR="/workspace/.opencode/state"
    export OPENCODE_DB="/workspace/.opencode/data/opencode.db"
    export OPENCODE_AUTH_JSON="/workspace/.opencode/data/auth.json"
    mkdir -p "$OPENCODE_CONFIG_DIR" \
             "$OPENCODE_DATA_DIR" \
             "$OPENCODE_CACHE_DIR" \
             "$OPENCODE_LOG_DIR" \
             "$OPENCODE_STATE_DIR"
    exec opencode "$@"
  '';
in
{

  ## Add project-specific packages
  environment.systemPackages = with pkgs; [
    opencode
    opencode_with_env
    vim
    jq
    git
    #nodejs_24
  ];

  environment.localBinInPath = true;

  environment.variables = {
    EDITOR = "vim";
  };

  # VM resources, firewall, ports and shares belong in nixaisylum.vm.nix
}
