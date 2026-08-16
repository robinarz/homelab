# homelab

A homelab for educational and entertainment purposes, built around Kubernetes on
[Talos Linux](https://www.talos.dev/).

## Development environment

This repo uses [Nix flakes](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop)
and [direnv](https://direnv.net/) to provide a reproducible toolchain.

### Prerequisites

- [Nix](https://nixos.org/download) with flakes enabled
- [direnv](https://direnv.net/) with the shell hook installed

### Usage

The environment activates automatically when you `cd` into the repo (via direnv):

```sh
direnv allow   # first time only
```

Or enter it manually:

```sh
nix develop
```

### Included tools

| Tool | Purpose |
|------|---------|
| `kubectl`, `kubectx` | Kubernetes CLI & context switching |
| `helm`, `kustomize` | Manifest templating / patching |
| `k9s` | Terminal Kubernetes UI |
| `talosctl`, `talhelper` | Talos Linux management |
| `flux` | GitOps continuous delivery |
| `cilium-cli` | Cilium CNI management |
| `sops`, `age` | Secret encryption |
| `kubeconform`, `kubeval` | Manifest validation |
| `jq`, `yq-go` | JSON / YAML processing |
| `task` (go-task) | Task automation |
| `helmfile` | Pre-Flux bootstrap |

## Architecture

See [`resources/homelab-topology.mermaid`](resources/homelab-topology.mermaid).

- **Host:** Proxmox VE on a Ryzen 7 3000 (8c/16t), 32GB RAM
- **Storage:** ZFS RAIDZ1 (~12TB) exported over NFS (RWX) from an LXC; `local-path` for config PVCs
- **Cluster:** 3× Talos VMs (control-plane + schedulable), Cilium CNI (kube-proxy replacement), Gateway API
- **Ingress:** no inbound ports — a `newt` pod holds an outbound WireGuard tunnel to a Pangolin VPS
- **GitOps:** Flux reconciles everything under `kubernetes/`; secrets via SOPS + age

## Repository layout

```
├── .sops.yaml                    # age encryption rules
├── Taskfile.yaml + .taskfiles/   # automation (talos, bootstrap)
├── bootstrap/                    # pre-Flux: Cilium + Flux via helmfile
├── talos/                        # talhelper cluster definition
│   ├── talconfig.yaml            #   node/network/disk config (edit for your LAN)
│   └── talenv.yaml               #   Talos / Kubernetes versions
└── kubernetes/
    ├── apps/                     # workloads by namespace (Flux Kustomizations)
    ├── flux/config/              # Flux entrypoint + cluster settings
    └── flux/repositories/        # Helm/OCI/Git sources
```

## Bring-up workflow (once Proxmox + the Talos VMs exist)

> Fill in the `TODO`s in `talos/talconfig.yaml` (LAN subnet, VIP, node IPs, install disk)
> and `bootstrap/flux-instance.values.yaml` (git repo URL) first.

```sh
task talos:schematic    # create the Image Factory schematic → prints the boot ISO URL
task talos:secret       # generate + SOPS-encrypt the Talos secret bundle (once)
task talos:generate     # render machine configs
task talos:apply NODE=192.168.1.11   # per node (first apply is --insecure)
task talos:bootstrap    # bootstrap etcd on the first node (once)
task talos:kubeconfig   # fetch ./kubeconfig
task bootstrap:apps     # install Cilium + Flux; Flux takes over from here
```

## Roadmap

- [x] Nix dev environment (flake + direnv)
- [x] Talos cluster definition (talhelper)
- [x] GitOps skeleton (Flux) + SOPS/age
- [x] CNI (Cilium) + LoadBalancer IPAM (L2)
- [x] Networking: Envoy Gateway (Gateway API) + `newt` (Pangolin tunnel)
- [x] Storage: `local-path-provisioner` (config) + direct NFS (`/data`)
- [x] Apps (`default` ns): Plex, Sonarr, Radarr, Prowlarr, Sabnzbd,
      Tautulli, Seerr, Recyclarr, Home Assistant
- [ ] Renovate for automated dependency updates
- [ ] Observability (Hubble, metrics)

### App layout

All workloads live in the `default` namespace under `kubernetes/apps/default/<app>/`.
Each app is an `app-template` HelmRelease exposed through the `envoy-internal`
Gateway via a built-in `HTTPRoute`; `newt` (in `network`) tunnels external
traffic in from the Pangolin VPS. Media shares a single NFS `/data` tree so
hardlinks stay intact; the *arr apps have deterministic SOPS-encrypted API keys.
