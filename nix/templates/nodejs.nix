## nodejs development environment
# Edit this file, then run 'nixaisylum sync' to apply changes.
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # 1. Frontend Runtime & Managers
    nodejs_22
    corepack_22
    pnpm
    bun
    typescript

    # 2. Agent Search & Exploration Tools
    ripgrep
    fd
    ast-grep
    jq
    tree

    # 3. Fast Linters & Formatters
    biome

    # 4. Headless Browser / Visual Testing
    # chromium
    playwright-test  # better use npm?
    playwright-driver.browsers

    # 5. Git & Utilities
    git
    gh
    curl
  ];

  environment.variables = {
    PLAYWRIGHT_BROWSERS_PATH = "${pkgs.playwright-driver.browsers}";
    PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";
  };
}
