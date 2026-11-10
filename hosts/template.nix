{ ... }:
{
  imports = [ ../modules/docker.nix ];
  networking.hostName = "nixos-lxc";
}
