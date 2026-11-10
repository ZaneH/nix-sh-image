{ config, lib, ... }:
{
  imports = [ ../modules/workload.nix ];
  networking.hostName = "freshrss";

  # For the official freshrss/freshrss image, NOT the LinuxServer image.
  # homelab.workload = { enable = true; image = "freshrss/freshrss@sha256:..."; };

  virtualisation.oci-containers.containers = lib.mkIf config.homelab.workload.enable {
    freshrss = {
      image = config.homelab.workload.image;
      ports = [ "8080:80" ];
      volumes = [
        "/var/lib/selfhosted/freshrss/data:/var/www/FreshRSS/data"
        "/var/lib/selfhosted/freshrss/extensions:/var/www/FreshRSS/extensions"
      ];
    };
  };
}
