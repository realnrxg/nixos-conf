{
  description = "Flakes conf";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";

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

    mangowm = {
	url = "github:mangowm/mango";
	inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, helium, home-manager, spicetify-nix, venta, mangowm, ... }@inputs: 
  let
    system = "x86_64-linux";
    pkgs-stable = import nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.nixosbtw = nixpkgs.lib.nixosSystem {
      inherit system;

      specialArgs = { inherit inputs pkgs-stable; };

      modules = [
        ./configuration.nix
	mangowm.nixosModules.mango
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
