# Arch Linux Ansible Box Builder

A build system for creating custom Arch Linux Vagrant boxes optimized for Ansible automation and testing. The box comes pre-configured with Python 3 and is ideal for use with Molecule, Ansible playbooks, and other automation workflows.

## Features

- **Python 3** pre-installed (required for Ansible modules)
- **Fully updated** Arch Linux system with latest packages
- **Optimized mirrors** via [reflector](https://wiki.archlinux.org/title/Reflector) with optional country filtering
- **Minimal footprint** with cleaned package cache and zeroed free space
- **Initialized pacman keyring** ready for package installations
- **Automated deployment** to HCP Vagrant Registry via Packer

## Requirements

| Tool | Purpose |
|------|---------|
| [Packer](https://www.packer.io/) | Build orchestration |
| [Vagrant](https://www.vagrantup.com/) | VM management (used by Packer's vagrant builder) |
| [VirtualBox](https://www.virtualbox.org/) | Virtualization provider |

### HCP Deployment (optional)

To deploy boxes to the HCP Vagrant Registry, create an [HCP Service Principal](https://developer.hashicorp.com/hcp/docs/hcp/admin/iam/service-principals) and export the credentials:

```bash
export HCP_CLIENT_ID="your-client-id"
export HCP_CLIENT_SECRET="your-client-secret"
```

## Quick Start

```bash
# Install Packer plugins
make init

# Configure reflector countries (optional)
cp archlinux-ansible.auto.pkrvars.hcl.example archlinux-ansible.auto.pkrvars.hcl

# Build locally
make build-only

# Build and deploy to HCP Registry
make build

# Build, deploy, and release
make release
```

## Usage

### Available Targets

```
make help       # Show all available targets
make init       # Install required Packer plugins
make validate   # Validate the Packer template
make build      # Build and deploy to HCP Registry (without release)
make build-only # Build locally without deploying to HCP
make release    # Build, deploy, and release on HCP Registry
make clean      # Remove build artifacts
```

### Direct Packer Commands

```bash
# Install plugins
packer init .

# Validate template
packer validate .

# Build locally (no deploy)
packer build -except=vagrant-registry .

# Build and deploy (no release)
packer build .

# Build, deploy, and release
packer build -var="no_release=false" .
```

### Configuration

Copy the example file and adjust as needed:

```bash
cp archlinux-ansible.auto.pkrvars.hcl.example archlinux-ansible.auto.pkrvars.hcl
```

Available variables in `archlinux-ansible.auto.pkrvars.hcl`:

| Variable | Default | Description |
|----------|---------|-------------|
| `registry_name` | `marcstraube` | HCP Registry username |
| `box_name` | `archlinux-ansible` | Name of the Vagrant box |
| `reflector_countries` | `""` (all) | Comma-separated list of countries for mirror selection |
| `no_release` | `true` | When true, uploaded version is not automatically released |

## Using the Box

### From HCP Vagrant Registry (Recommended)

A pre-built version is available on [HCP Vagrant Registry](https://portal.cloud.hashicorp.com/vagrant/discover/marcstraube/archlinux-ansible):

**Vagrantfile:**

```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "marcstraube/archlinux-ansible"
end
```

**molecule.yml:**

```yaml
platforms:
  - name: instance
    box: marcstraube/archlinux-ansible
```

### Local Usage

After building locally with `make build-only`:

```bash
vagrant box add --name archlinux-ansible output-archlinux/package.box
```

Then reference `archlinux-ansible` in your Vagrantfile or molecule.yml.

## Versioning

This project uses Calendar Versioning (CalVer) with the format `YYYYMMDD.hhmmss` to ensure unique, timestamped versions for each build.

## License

MIT License - see [LICENSE](LICENSE) for details.
