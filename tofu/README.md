# tofu — Proxmox VM provisioning

OpenTofu config that creates the three Talos VMs on Proxmox (API-only, no SSH),
using the [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox) provider.

## 1. Create the automation user + API token (once, on Proxmox)

Run as root (web-UI Shell or `sudo -i`). A dedicated **PVE-realm** service account
with a scoped role — never `root@pam`.

```bash
# A role with just the privileges the provider needs
pveum role add TerraformProv -privs "\
Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit \
Pool.Allocate Pool.Audit SDN.Use Sys.Audit Sys.Console Sys.Modify \
VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit \
VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options \
VM.Migrate VM.PowerMgmt"

# The service user and role binding at the root path
pveum user add tofu@pve
pveum acl modify / -user tofu@pve -role TerraformProv

# API token; --privsep 0 makes it inherit the user's role (simplest).
# The secret is printed ONCE — copy it now.
pveum user token add tofu@pve automation --privsep 0
```

The token value is `tofu@pve!automation=<uuid>`.

## 2. Configure

Non-secret inputs go in `terraform.tfvars`; the API token lives **encrypted** in
`secrets.sops.yaml` and is injected only at runtime (never exported to disk or
shell history).

```bash
cp terraform.tfvars.example terraform.tfvars   # endpoint, node, datastores, ISO URL
task infra:edit-secrets                        # opens SOPS editor; paste the real token
```

Get the ISO URL first with `task talos:schematic` and paste it into `talos_iso_url`.

## 3. Provision

Secrets are decrypted on the fly via `sops exec-env` — no manual exports:

```bash
task infra:init
task infra:plan
task infra:apply
```

This downloads the Talos ISO to the node and creates `talos-01..03`
(4 vCPU / 8 GB / 100 GB, virtio-scsi `→ /dev/sda`, virtio NIC, QEMU agent on).

## 4. Bring up Talos

The VMs boot the ISO into **maintenance mode** (DHCP). Find each node's temporary
IP (Proxmox VM Summary shows it via the guest agent), then from the repo root:

```bash
task talos:secret        # once
task talos:generate
task talos:apply NODE=<maintenance-ip>   # per node; first apply is --insecure
task talos:bootstrap     # once, on the first node
task talos:kubeconfig
task bootstrap:apps      # Cilium + Flux
```

Applying the machine config sets each node's **static IP** (from `talconfig.yaml`),
after which it reboots off the disk.

## Notes

- Everything here is **API-only** — it works even though root SSH is disabled and
  `tofu@pve` has no Linux login.
- `terraform.tfvars` and state are gitignored; `.terraform.lock.hcl` and the
  SOPS-**encrypted** `secrets.sops.yaml` are committed.
- Edit the token any time with `task infra:edit-secrets` (or `sops tofu/secrets.sops.yaml`).
- Later, when Infisical is running, swap `sops exec-env` for `infisical run --` in
  `.taskfiles/infra/Taskfile.yaml` — same pattern, central vault.
- Keep `talos_version` here in sync with `talos/talenv.yaml`.
