# Agent Guidelines

If I reject a change, stop and ask me why I rejected it, instead of continuing to propose other changes.

## Project Overview

This project builds a custom Arch Linux Vagrant box optimized for Ansible development and testing. The box is published to the HCP Vagrant Registry as `marcstraube/archlinux-ansible`.

**Build pipeline:** `packer build .` (provision VM → package .box → upload to HCP Registry)

## Architecture

| File | Purpose |
|------|---------|
| `archlinux-ansible.pkr.hcl` | Packer HCL template: source, provisioning, and registry upload |
| `Makefile` | Convenience wrapper around Packer commands |
| `*.auto.pkrvars.hcl` / `*.auto.pkrvars.hcl.example` | User configuration (reflector countries, etc.) |

## Key Conventions

- **CalVer versioning** - Format `YYYYMMDD.hhmmss`, auto-generated via `formatdate()` + `timestamp()` in Packer.
- **HCP Auth via Service Principal** - `HCP_CLIENT_ID` + `HCP_CLIENT_SECRET` environment variables. No interactive login needed.
- **Makefile help system** - Targets use inline `## Comment` after the colon for `make help` output. The awk pattern is `^[a-zA-Z_-]+:.*##`.

## Provisioning Order (in Packer shell provisioner)

1. Initialize pacman keyring
2. Update `archlinux-keyring`
3. Full system upgrade (`pacman -Syu`) - must run before installing new packages to handle transitions (e.g. `gcc-libs` → `libgcc` + `libstdc++`)
4. Install `reflector` and Python 3
5. Update mirrorlist with reflector (optional country filtering)
6. Cleanup (pacnew files, package cache, disk zeroing, history)

## Dependencies

- **Build:** Packer, Vagrant, VirtualBox
- **Deploy:** HCP Service Principal credentials (`HCP_CLIENT_ID`, `HCP_CLIENT_SECRET`)
- **Provisioning (in-VM):** reflector (installed automatically)

## Language

All code, comments, and documentation must be in English.
