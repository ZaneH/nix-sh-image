{ config, lib, ... }:
let
  cfg = config.homelab.workload;
in
{
  imports = [ ./docker.nix ];

  options.homelab.workload = {
    enable = lib.mkEnableOption "the host's Docker workload (enable after data preparation)";
    image = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Explicit Docker image tag or, preferably, digest. Match the existing deployment for migration.";
    };
  };

  config.assertions = [
    {
      assertion = !cfg.enable || cfg.image != "";
      message = "Set homelab.workload.image to an explicit image version before enabling the workload.";
    }
  ];
}
