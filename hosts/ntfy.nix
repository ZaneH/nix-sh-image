{ config, lib, ... }:
{
  imports = [ ../modules/workload.nix ];
  networking.hostName = "ntfy";

  # After preparing config/data, choose the existing deployment's image:
  # homelab.workload = { enable = true; image = "binwiederhier/ntfy@sha256:..."; };

  virtualisation.oci-containers.containers = lib.mkIf config.homelab.workload.enable {
    ntfy = {
      image = config.homelab.workload.image;
      cmd = [ "serve" ];
      ports = [ "8080:80" ];
      volumes = [
        "/var/lib/selfhosted/ntfy/cache:/var/cache/ntfy"
        "/var/lib/selfhosted/ntfy/config:/etc/ntfy:ro"
      ];
    };
  };
}
