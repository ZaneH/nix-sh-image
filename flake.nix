{
  description = "Reproducible NixOS Proxmox LXC templates and service hosts";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      configurationSource = nixpkgs.lib.fileset.toSource {
        root = ./.;
        fileset = nixpkgs.lib.fileset.unions [
          ./flake.nix
          ./flake.lock
          ./modules
          ./hosts
          ./README.md
        ];
      };
      mkHost =
        name:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit configurationSource; };
          modules = [
            ./modules/base.nix
            ./hosts/${name}.nix
          ];
        };
    in
    {
      nixosConfigurations = nixpkgs.lib.genAttrs [ "template" "pihole" "ntfy" "freshrss" ] mkHost;

      packages.${system} = {
        template = self.nixosConfigurations.template.config.system.build.tarball;
        default = self.packages.${system}.template;
      };

      checks.${system} = nixpkgs.lib.mapAttrs (
        _: host: host.config.system.build.toplevel
      ) self.nixosConfigurations;

      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}
