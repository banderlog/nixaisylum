# nixaisylum

Project-local NixOS MicroVM environments with meatbag friendly codebase.


## Quickstart

```bash
nix run github:banderlog/nixaisylum init
nix run github:banderlog/nixaisylum shell
```


## Commands

```text
init [TPL...]     Initialize the current project from one or more templates (default: minimal)
templates         List available templates
build             Build the VM
start             Build if needed and start the VM
stop              Stop the VM
shell             Enter the VM
sync              Rebuild changed configuration and restart if running
status            Show project state
destroy           Remove generated state and nixaisylum.vm.nix
```

Notes:

- `init` creates the editable `nixaisylum.vm.nix` plus the chosen modules in `nixaisylum/`
- all build/state artifacts stored in `.nixaisylum-vm/`, except `nixaisylum.vm.nix` and `nixaisylum/`
- `sync` applies changes to `nixaisylum.vm.nix`
- the project directory is mounted live at `/workspace` and it is writeable for VM, consider it bidirectional share
- the guest user uses the host user's UID and primary GID, so rootless `virtiofsd` can create files in `/workspace` (not only on NixOS)
- all other VM filesystem except the `/tmp` is read only
- all filesystem except the `/workspace` is ephemerial -- it will be erased on VM reboot


## Templates

A template is a NixOS module. `init` copies the ones you pick into `nixaisylum/`
and generates a `nixaisylum.vm.nix` that imports them, so they combine:

```bash
nix run github:banderlog/nixaisylum templates                  # see what's available
nix run github:banderlog/nixaisylum init python                # one module
nix run github:banderlog/nixaisylum init python claudecode     # combined
```

This gives you:

```text
nixaisylum.vm.nix      imports + VM options (RAM, vCPUs, ports, firewall)
nixaisylum/
├── python.nix         edit to change packages
└── claudecode.nix
```

Both are git-tracked, so your edits stay under version control. Run
`nixaisylum sync` after changing either.

To add a module later, copy it in and add one line to `imports` -- `init` never
overwrites an existing `nixaisylum.vm.nix`.

### How combining works

Modules only ever declare *what goes inside* the VM: packages, services,
environment variables. Those merge -- package lists concatenate and variables
merge per key.

VM-level options (`microvm.mem`, `microvm.vcpu`, `microvm.forwardPorts`,
`networking.firewall.*`) live **only** in `nixaisylum.vm.nix`. NixOS cannot
merge two conflicting scalars, so `mem` set by two modules at once would be a
build error. Keeping them in one file also means there is a single place to look
when tuning the VM. Sensible defaults (4 GB RAM, 4 vCPUs, firewall off) come
from the base config; uncomment a line in `nixaisylum.vm.nix` to override.

The firewall is **off by default** -- enabling it is an explicit user decision.
Forwarding ports is likewise opt-in: services are reachable inside the VM
regardless, and only need forwarding to be used from the host.


### Hacking on nixaisylum itself

The `dev` template carries the toolchain for working on this repo, so you can
develop nixaisylum inside a nixaisylum VM:

```bash
nix run github:banderlog/nixaisylum init dev
nix run github:banderlog/nixaisylum shell
nixaisylum-check /workspace     # run all gates in seconds
```

`nixaisylum-check` replicates what `nix build` enforces, but fast. It covers the
failure modes that have actually shipped:

| check | catches |
|---|---|
| `shellcheck nixaisylum.sh` | `writeShellApplication` lints as a **build gate** -- one warning breaks `nix run` for everyone |
| placeholder substitution | `flake.nix` not replacing a `@PLACEHOLDER@`; `replaceStrings` no-ops silently, so it builds fine and breaks at runtime |
| nix parse | syntax errors in any template or flake |
| git tracking | a new template that is untracked, and so invisible to `nix run` (see below) |
| module purity | a template setting `microvm.*` / `networking.firewall.*`, which makes it unmergeable with other templates |

It ships `shellcheck` itself, so you can reproduce a build failure without a
full rebuild. Note the build gate is strict: **any** shellcheck warning fails it.


### Adding a template (contributing)

Templates live in `nix/templates/`.
Each is a standalone NixOS module whose first line is a `##` description:

```nix
## Rust toolchain with rust-analyzer (rust.nix example)
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ rustc cargo rust-analyzer ];
}
```

Then **`git add` it**:

```bash
git add nix/templates/rust.nix
```

`nix run` builds from the git tree, so an untracked file does not exist as far as
the flake is concerned -- your new template just will not show up in
`nixaisylum templates`, with no error to explain why. Staging is enough; no
commit is needed. `nixaisylum-check` flags this.

There is no manifest to update, the name comes from the filename and the description from that first line.

Keep templates composable:

- do **not** set `microvm.*` or `networking.firewall.*` -- those belong in `nixaisylum.vm.nix`
- prefer merge-friendly options (`environment.systemPackages`, `environment.variables`)
- a scalar your template must set (e.g. `services.foo.port`) makes it conflict
  with any other template setting the same one -- that is fine, just keep the
  scope of each template narrow


## Acknowledgements

Inspired by <https://github.com/hamidr/nixcage> and <https://github.com/razvanz/nixbox>


### Why this repo exist

- nixbox wants you to permit 35 sudo commands to edit your iptables, interfaces and dnsmasq
- nixcage decided to switch from microVM to containers: <https://github.com/hamidr/nixcage/issues/1>
- both repos are under heavy AI development and have overblown, non-meatbag-friendly ~1K-line bash scripts at their cores
