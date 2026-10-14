## tools for hacking on nixaisylum itself (shellcheck, nixfmt, nixaisylum-check)
{ pkgs, ... }:
let
  # Runs the same gates the flake does, but in seconds instead of a full build.
  #  Every check here corresponds to a bug that actually shipped.
  nixaisylum-check = pkgs.writeShellScriptBin "nixaisylum-check" ''
    set -uo pipefail
    cd "''${1:-/workspace}" || { echo "no such dir: ''${1:-/workspace}" >&2; exit 1; }

    rc=0
    pass() { printf '  \e[32mok\e[0m   %s\n' "$1"; }
    fail() { printf '  \e[31mFAIL\e[0m %s\n' "$1"; rc=1; }

    echo "== shellcheck =="
    # flake.nix builds nixaisylum.sh with writeShellApplication, which lints it
    #  as a BUILD GATE: any warning there breaks 'nix run' for everyone.
    if shellcheck nixaisylum.sh; then
      pass "nixaisylum.sh clean"
    else
      fail "nixaisylum.sh (this breaks 'nix run' -- writeShellApplication gates on it)"
    fi

    echo "== placeholder substitution =="
    # The nixasylum -> nixaisylum rename left flake.nix replacing @NIXASYLUM_*@
    #  while the script had @NIXAISYLUM_*@. replaceStrings no-ops silently on a
    #  miss, so it BUILT FINE and failed at runtime with an unusable NIX_DIR.
    missing=""
    while read -r ph; do
      [ -n "$ph" ] || continue
      grep -qF "$ph" flake.nix || missing="$missing $ph"
    done < <(grep -oE '@[A-Z_]+@' nixaisylum.sh | sort -u)
    if [ -z "$missing" ]; then
      pass "every @PLACEHOLDER@ in nixaisylum.sh is replaced by flake.nix"
    else
      fail "flake.nix never replaces:$missing (silent no-op -> broken at runtime)"
    fi

    echo "== nix parse =="
    bad=""
    for f in flake.nix nix/flake.nix nix/templates/*.nix; do
      nix-instantiate --parse "$f" >/dev/null 2>&1 || bad="$bad $f"
    done
    if [ -z "$bad" ]; then
      pass "all nix files parse"
    else
      fail "syntax errors in:$bad"
    fi

    echo "== git tracking =="
    # 'nix run' builds from the git tree, so UNTRACKED files simply do not exist
    #  as far as the flake is concerned: a new template silently fails to appear
    #  in 'nixaisylum templates'. Staging is enough, no commit needed.
    if git -C . rev-parse --git-dir >/dev/null 2>&1; then
      untracked=$(git -C . ls-files --others --exclude-standard -- nix/templates flake.nix nix/flake.nix nixaisylum.sh)
      if [ -z "$untracked" ]; then
        pass "no untracked build inputs"
      else
        fail "untracked, so invisible to 'nix run' (git add them):"
        while read -r u; do
          [ -n "$u" ] && printf '         %s\n' "$u"
        done <<< "$untracked"
      fi
    else
      pass "not a git repo, skipping"
    fi

    echo "== module purity =="
    # Modules must not set VM-level options: NixOS cannot merge two scalars, so
    #  two modules both setting microvm.mem is a hard build error. These live
    #  only in nixaisylum.vm.nix. Comments are allowed (they document the split).
    dirty=""
    for f in nix/templates/*.nix; do
      # dev.nix is exempt: it quotes these option names inside this very check
      [ "$f" = "nix/templates/dev.nix" ] && continue
      # match assignments only ('microvm.mem ='), not prose, and drop comments
      grep -vE '^[[:space:]]*#' "$f" \
        | grep -qE '^[[:space:]]*(microvm\.|networking\.firewall)[a-zA-Z.]*[[:space:]]*=' \
        && dirty="$dirty $f"
    done
    if [ -z "$dirty" ]; then
      pass "no module sets microvm.* or networking.firewall.*"
    else
      fail "VM-level options leaked into:$dirty"
    fi

    echo
    [ "$rc" -eq 0 ] && echo "all checks passed" || echo "some checks FAILED" >&2
    exit "$rc"
  '';
in
{
  environment.systemPackages = with pkgs; [
    nixaisylum-check

    # The build gate, so you can reproduce CI failures locally
    shellcheck
    shfmt

    # nixfmt-rfc-style is a deprecated alias for nixfmt on nixpkgs 26.05
    nixfmt

    git
    jq
    ripgrep
    vim
    file
    tree
  ];

  environment.variables.EDITOR = "vim";

  # VM resources, firewall, ports and shares belong in nixaisylum.vm.nix
}
