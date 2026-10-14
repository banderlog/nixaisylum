## bare VM with git, curl and vim
# Edit this file, then run 'nixaisylum sync' to apply changes.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
  ];

  environment.variables = {
    EDITOR = "vim";
  };
}
