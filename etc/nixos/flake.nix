{
  description = "Flakes conf";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    helium = {
      url = "github:schembriaiden/helium-browser-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
    venta.url = "github:realnrxg/venta";
  };

  outputs = { self, nixpkgs, helium, home-manager, spicetify-nix, venta, ... }: {
    nixosConfigurations.nixosbtw = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      modules = [
        ./configuration.nix

        home-manager.nixosModules.home-manager

        {
          environment.systemPackages = [
            helium.packages.x86_64-linux.default
          ];

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.extraSpecialArgs = {
            inherit spicetify-nix venta;
          };

          home-manager.users.nrxg = import ./home.nix;
        }
      ];
    };
  };
}
