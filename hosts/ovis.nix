{ config, lib, ... }:
{
  imports = [ ../modules/ovis.nix ];

  homelab.ovis = {
    enable = true;
    user = "me";
  };
}
