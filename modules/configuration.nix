{ configurationSource, pkgs, ... }:
{
  # Keep a writable copy of the build's source in each fresh container.
  # Never replace an existing checkout or locally edited configuration.
  systemd.services.seed-nixos-configuration = {
    description = "Seed editable NixOS configuration";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    unitConfig.ConditionPathExists = "!/etc/nixos";
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      UMask = "0077";
    };
    script = ''
      # Also preserve dangling symlinks, which ConditionPathExists can't detect.
      if [ -e /etc/nixos ] || [ -L /etc/nixos ]; then
        exit 0
      fi
      staging=$(mktemp -d /etc/.nixos-source.XXXXXX)
      trap 'rm -rf "$staging"' EXIT
      cp -R ${configurationSource}/. "$staging/"
      chmod -R u+w "$staging"
      # Same filesystem: publish the complete tree atomically.
      mv -T "$staging" /etc/nixos
    '';
  };
}
