# Eir — Custom NixOS Recovery USB

**Eir** (named after the Norse goddess associated with medical skill and healing) is a custom, reproducible NixOS-based live recovery USB image built using Nix Flakes on NixOS 26.05.

It is designed to replace generic live Linux ISOs (Arch, Mint, Ubuntu) with a tailorable, deterministic rescue image that can be built and updated reproducibly. It will also include the users personal terminal setup for familiarity.

---

## Project Structure

```
.
├── flake.nix          # Entrypoint defining dependencies and nixosConfigurations.recovery
├── flake.lock         # Pinned Git commits for dependencies (nixpkgs 26.05)
└── configuration.nix  # NixOS module configuring recovery packages, tools, and services
```

---

## Build & Usage Quick Reference

### Evaluating & Building the ISO Image

To evaluate and build the recovery ISO using the flake:

```bash
nix build .#nixosConfigurations.recovery.config.system.build.isoImage
```

Upon completion, a `./result` symlink will point to the build output in `/nix/store`, containing the `.iso` file under `./result/iso/`.

### Updating Dependencies

To update `nixpkgs` to the latest commit on the `nixos-26.05` release branch:

```bash
nix flake update
```

To rollback an update:

```bash
git checkout flake.lock
```

---

## Technical Concept Notes

For a detailed conceptual breakdown of Nix primitives (Derivations, Nix Store, Flakes, Module System, and Image Building), see:
[Nix Foundations Reference](.pi/notes.local/nix-foundations-reference.md)
