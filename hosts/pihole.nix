{ config, lib, ... }:
{
  imports = [ ../modules/workload.nix ];
  networking.hostName = "pihole";

  # This skeleton targets Pi-hole v6. Check the existing version before migration.
  # homelab.workload = { enable = true; image = "pihole/pihole@sha256:..."; };

  virtualisation.oci-containers.containers = lib.mkIf config.homelab.workload.enable {
    pihole = {
      image = config.homelab.workload.image;
      ports = [
        "53:53/tcp"
        "53:53/udp"
        "8080:80"
      ];
      environment.FTLCONF_dns_listeningMode = "ALL";
      volumes = [ "/var/lib/selfhosted/pihole/etc-pihole:/etc/pihole" ];
      # Runtime file, not a Nix store path. Set FTLCONF_webserver_api_password.
      environmentFiles = [ "/var/lib/selfhosted/pihole/secrets.env" ];
    };
  };
}
