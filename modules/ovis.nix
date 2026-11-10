{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.homelab.ovis;
in
{
  options.homelab.ovis = {
    enable = lib.mkEnableOption "Ovis terminal client and web server";

    user = lib.mkOption {
      type = lib.types.str;
      description = "The host user whose terminal sessions Ovis will attach to.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/ovis";
      description = "State directory where the Ovis repository will be cloned and built.";
    };
  };

  config = lib.mkIf cfg.enable {
    # 1. Provision the exact host dependencies Ovis requires
    environment.systemPackages = with pkgs; [
      bun
      git
      herdr
      nodejs_22 # Fallback required by Ovis if the Rust PTY host fails to load
    ];

    # 2. Define the Ovis systemd service
    systemd.services.ovis = {
      description = "Ovis Web Terminal";
      after = [
        "network.target"
        "tailscaled.service"
      ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        User = cfg.user;
        WorkingDirectory = cfg.dataDir;

        # Clone the repo and install Bun dependencies on first startup
        ExecStartPre = pkgs.writeShellScript "ovis-init" ''
          if [ ! -d "${cfg.dataDir}/.git" ]; then
            ${pkgs.git}/bin/git clone https://github.com/devswha/ovis.git ${cfg.dataDir}
          fi
          cd ${cfg.dataDir}
          ${pkgs.bun}/bin/bun install
        '';

        # Run the server
        ExecStart = "${pkgs.bun}/bin/bun run start";
        Restart = "always";
        RestartSec = "10s";

        # Load secrets (like OVIS_TOKEN) from an environment file you create manually
        EnvironmentFile = "-${cfg.dataDir}/secrets.env";
        Environment = [
          "HOST=127.0.0.1"
          "PORT=7317"
          # Optional: Allows automatic Tailscale login without pairing codes
          # on devices owned by your Tailnet account
          "OVIS_TAILSCALE_SERVE_ONLY=1"
        ];
      };
    };

    # Ensure the state directory exists with correct permissions
    systemd.tmpfiles.rules = [
      "d ${cfg.dataDir} 0750 ${cfg.user} users -"
    ];
  };
}
