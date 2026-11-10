# NixOS Proxmox LXC

A separate infrastructure flake: one reusable, headless LXC template, shared defaults,
and configurations for Pi-hole, ntfy, and FreshRSS. No VM or Firecracker involved.
Currently targets **x86_64-linux** and NixOS 26.05.

## What is included

- Upstream NixOS Proxmox LXC integration; unprivileged containers.
- Proxmox-managed networking, Nix-managed hostnames.
- Docker, curl, Git, Vim, htop, jq, tmux, and Node.js (for Pi).
- `admin` with key-only SSH and passwordless sudo. Root SSH is disabled.
- Disabled-by-default Docker service examples with explicit persistent bind mounts.
- An editable copy of the image's source configuration, seeded at `/etc/nixos`
  on first boot without network access.

Pi itself is not installed yet; Node.js is available for installing its CLI. Do not
put agent credentials, private keys, or application secrets in this repo/image.

## 1. Set up access and build

Add your public SSH key to `modules/access.nix`. There is deliberately no default
password or private key. Without an authorized key, SSH will not work; Proxmox's
`pct enter` remains the recovery/bootstrap path. Passwordless sudo grants full
administration to admin and any agent it runs. It is not a sandbox.

From a Linux Nix builder:

```sh
# New files must be tracked for Git-backed flakes to see them.
git add .
nix flake check --no-build
nix build .#template
ls -lh result/tarball/
```

The resulting `.tar.xz` is a Proxmox container template, not a VM disk.
Building this may take time and disk space; the Nix store makes this larger than
an Alpine root filesystem. `flake.lock` pins the actual Nixpkgs revision.

## 2. Create a container on Proxmox

Copy the generated tarball into a template-capable storage, e.g.
`/var/lib/vz/template/cache/` for the usual `local` storage. On the Proxmox host,
adapt the storage, bridge, ID, filename, and resource limits:

```sh
pct create 120 local:vztmpl/REPLACE-WITH-GENERATED-FILENAME.tar.xz \
  --ostype unmanaged \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --hostname nixos-lxc \
  --rootfs local-lvm:16 \
  --memory 1024 --swap 512 --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --onboot 1
pct start 120
pct enter 120
```

`unmanaged` prevents Proxmox distro setup scripts from rewriting NixOS files.
NixOS sets the hostname on activation, so set it in `hosts/<name>.nix` too.
DHCP here is an example; a DNS server such as Pi-hole should have a stable address.

Docker inside unprivileged LXC is host/kernel/storage dependent. Nesting and
keyctl are the starting point, not a guarantee. Test `sudo docker run --rm
hello-world` before deployment. Do not disable AppArmor or use privileged LXC
as a blanket fix. Enable only the features needed for your workload. Nested
Docker shares the Proxmox kernel; it is not VM-level isolation.

## 3. Apply a host configuration

The image includes the exact configuration source and lock file used to build
it. On first boot, `seed-nixos-configuration.service` copies them to a writable,
root-owned `/etc/nixos`. No manual clone, Git credentials, or network access is
needed. The service never overwrites an existing `/etc/nixos`, even on rebuilds.
Only the flake, lock file, modules, hosts, and README are included. Those files
are public Nix-store content: never put secrets in them.

Inside the new container (as admin, or via `pct enter`):

```sh
cd /etc/nixos
sudo vim hosts/ntfy.nix
sudo nixos-rebuild switch --flake .#ntfy
```

This is a source snapshot, **not a Git checkout**: it has no `.git` directory or
remote. You can edit/rebuild immediately; `git pull` is only available after
switching to an actual checkout. To do that later, preserve your local edits,
clone the repository to a separate directory, then move the snapshot aside and
put the checkout at `/etc/nixos`. Do not delete your only copy of local changes.
No Git remote is currently configured in this repository, so the image cannot
infer a clone URL.

For a container built from an older image, apply the new configuration once
or rebuild the template. If `/etc/nixos` already exists, populate it manually;
the seed service deliberately leaves it untouched.

Replace `ntfy` with `pihole` or `freshrss`. These initially configure the machine
and Docker **without starting the application**. A root-owned checkout is
intentional: changes there affect root-executed system configuration. Use sudo
to edit/pull, or deploy from your administrative machine later.

To activate an application:

1. Inspect the existing Compose configuration, exact image, volume paths,
   database dependencies, environment, and permissions.
2. Back up its data and test a restore. Stop the old service before a final copy.
3. Prepare the bind mounts listed in `hosts/<name>.nix`, with the ownership
   expected by the image. Never point two running instances at the same data.
4. Configure secrets at runtime, outside Git and the Nix store.
5. Set `homelab.workload.image` to the matching image/tag or preferably digest,
   then set `homelab.workload.enable = true` and rebuild.
6. Test on a separate IP before switching DNS/proxy traffic.

The examples are starting points, **not existing-service migrations**:

| Host | Image family | Persistent paths inside LXC | Published ports |
| --- | --- | --- | --- |
| pihole | `pihole/pihole` v6 | `/var/lib/selfhosted/pihole/etc-pihole` | TCP/UDP 53, HTTP 8080 |
| ntfy | `binwiederhier/ntfy` | `/var/lib/selfhosted/ntfy/{cache,config}` | HTTP 8080 |
| freshrss | official `freshrss/freshrss` | `/var/lib/selfhosted/freshrss/{data,extensions}` | HTTP 8080 |

Pi-hole requires a root-readable `secrets.env` (mode 0600) containing
`FTLCONF_webserver_api_password=...`. It is DNS-only here, not a DHCP server;
v5 migrations and custom dnsmasq configuration need separate review.

For ntfy, supply `/etc/ntfy/server.yml` through the config bind mount and verify
its cache/auth database paths are persistent. Configure authentication and access
policy before exposing it; defaults may allow unauthenticated publishing/reading.
FreshRSS may also depend on an external database not represented here. A
LinuxServer FreshRSS `/config` volume is not interchangeable with these paths.

Docker published ports can bypass the NixOS host firewall's normal input rules.
Treat the listed ports as exposed on the container's interfaces. Restrict access
with a verified Proxmox/network firewall, or change the port bindings for your
proxy topology. No TLS/reverse proxy is configured. Do not expose these directly
to the Internet without configuring authentication, TLS, and access controls.

## Updating existing containers

For the bundled snapshot, edit files under `/etc/nixos` and rebuild:

```sh
cd /etc/nixos
sudo vim hosts/ntfy.nix
sudo nixos-rebuild switch --flake .#ntfy
```

For centrally managed updates, use a real checkout as described above, commit
changes in the central repository, then `sudo git pull --ff-only` before
rebuilding each host. A new system build does not overwrite the writable source
snapshot with a newer one; source synchronization is separate from activation.

For package/security updates, update the lock **centrally**, test on one host,
and commit it before rolling it out:

```sh
nix flake update nixpkgs
nix flake check --no-build
# On a test container using the updated checkout:
sudo nixos-rebuild switch --flake .#ntfy
# Commit flake.lock, then pull/rebuild other hosts.
```

Docker application images are pinned separately in host configuration; updating
Nixpkgs does not update them. Keep their versions/digests current deliberately.
Do not bump `system.stateVersion` for routine upgrades. The kernel belongs to
Proxmox and must be updated there. There are no automatic updates configured.

Rollback system packages/configuration with:

```sh
sudo nixos-rebuild switch --rollback
```

Also revert the bad Git change. This does NOT undo database migrations, restore
volumes, or roll back other mutable state. Back up application data separately;
Proxmox bind mounts may not be included in container backups.

## Template lifecycle and recovery

Rebuild `nix build .#template` periodically for **new** containers; it does not
update existing ones. Only the template configuration belongs in the template:
never distribute a running service container's secrets or data as a golden image.
The build does not embed generated SSH host keys or a machine ID. If you clone
an already-booted container instead, reset its machine ID and SSH host keys before
network access so every instance has a unique identity.

If SSH breaks, use `pct enter <id>` from Proxmox to repair or roll back. Keep
old generations until confident in a deployment, then explicitly collect them;
automatic garbage collection is deliberately disabled to preserve rollback.

For another service, add `hosts/<name>.nix` and its name to `flake.nix`.
Later we can add remote deployment, secret management, and service-specific
migration plans without changing this repository structure.
