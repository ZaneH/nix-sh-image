{ ... }:
{
  virtualisation.docker.enable = true;
  virtualisation.oci-containers.backend = "docker";
  # No Docker group: access to its socket is effectively root access. Use sudo.
}
