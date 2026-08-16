{
  description = "Homelab - Kubernetes on Talos development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          name = "homelab";

          packages = with pkgs; [
            # Kubernetes core
            kubectl
            kubernetes-helm
            kustomize
            k9s
            kubectx

            # Talos
            talosctl
            talhelper

            # GitOps / secrets
            fluxcd
            sops
            age

            # Networking / CNI
            cilium-cli

            # Validation / linting
            kubeconform

            # Automation / bootstrap
            go-task
            helmfile
            opentofu

            # Utilities
            jq
            yq-go
            git
            direnv
          ];

          shellHook = ''
            echo "🏠 homelab dev shell"
            echo "   kubectl   $(kubectl version --client -o yaml 2>/dev/null | grep gitVersion | head -1 | awk '{print $2}')"
            echo "   talosctl  $(talosctl version --client --short 2>/dev/null | head -1)"
            echo "   k9s       $(k9s version --short 2>/dev/null | grep Version | awk '{print $2}')"
          '';
        };
      }
    );
}
