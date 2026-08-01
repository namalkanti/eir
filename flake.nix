{
  description = "Eir - Custom NixOS Recovery USB";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    dotfiles = {
      url = "github:namalkanti/dotfiles";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, dotfiles }: {
    packages.x86_64-linux.default = self.nixosConfigurations.recovery.config.system.build.isoImage;

    nixosConfigurations.recovery = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        ./configuration.nix
      ];
      specialArgs = { inherit dotfiles; };
    };
  };
}
