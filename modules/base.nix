{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ./access.nix
    ./configuration.nix
  ];

  proxmoxLXC = {
    privileged = false;
    manageNetwork = false; # Proxmox supplies networking.
    manageHostName = true; # Each host configuration supplies its name.
  };

  # getty@ is also exposed as autovt@. On current NixOS the upstream
  # Proxmox module's autovt@ override does not fix the getty@ template.
  # LXC has tty1, but no virtual-console device tty0.
  systemd.services."getty@".unitConfig.ConditionPathExists = lib.mkForce [
    ""
    "/dev/%I"
  ];

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.settings.auto-optimise-store = true;
  # Keep old generations until explicitly cleaned up, for rollback.
  nix.gc.automatic = false;

  environment.systemPackages = with pkgs; [
    curl
    git
    vim
    htop
    jq
    tmux
    nodejs # Pi prerequisite; install the CLI separately for now.
  ];
  environment.variables.EDITOR = "vim";

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  # Do not bump this as part of routine package updates.
  system.stateVersion = "26.05";
}
