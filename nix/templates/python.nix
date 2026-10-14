## python3 with uv and ruff
# Edit this file, then run 'nixaisylum sync' to apply changes.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    curl
    vim

    python3
    uv
    ruff
    ripgrep
    jq
    file
  ];

  # Automatically adds ~/.local/bin to PATH
  environment.localBinInPath = true;

  # Standard environment variables
  environment.variables = {
    UV_LINK_MODE = "copy";
    UV_CACHE_DIR="/workspace/.uv-cache";
    LD_LIBRARY_PATH = "/run/current-system/sw/share/nix-ld/lib";
  };

  # for uv wheels
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      # System libraries required by numpy and other wheels
      stdenv.cc.cc.lib
      glibc
      zlib
      gfortran.cc.lib
      libffi
      openssl
      file
      ## streamlit requirements
      #libxcb
      #libGL
      #glib
    ];
  };
}
