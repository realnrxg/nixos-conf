{ pkgs, spicetify-nix, venta,  ... }:

let
  spicePkgs = spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.username = "nrxg";
  home.homeDirectory = "/home/nrxg";
  home.stateVersion = "26.05";

  imports = [
    spicetify-nix.homeManagerModules.spicetify
  ];

  programs.spicetify = {
    enable = true;

    enabledExtensions = with spicePkgs.extensions; [
      adblockify
      hidePodcasts
      shuffle
    ];

    theme = spicePkgs.themes.catppuccin;
    colorScheme = "mocha";
  };

  home.packages = with pkgs; [
    venta.packages.${pkgs.stdenv.hostPlatform.system}.default
    kdePackages.qt6ct
    dconf
    glib
    adwaita-qt
    gnome-themes-extra
    adwaita-icon-theme
  ];

  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    cursorTheme = {
      name = "Afterglow-cursors";
      package = null;
      size = 24;
    };
  };

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "Adwaita-dark";
      icon-theme = "Adwaita";
      cursor-theme = "Afterglow-cursors";
      font-name = "Sans 11";
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt;
    };
  };

  home.sessionVariables = {
    XDG_CURRENT_DESKTOP = "Hyprland";
    GTK_THEME = "Adwaita-dark";

    XCURSOR_THEME = "Afterglow-cursors";
    XCURSOR_SIZE = "24";

    XCURSOR_PATH = "$HOME/.local/share/icons:$XCURSOR_PATH";

    XDG_DATA_DIRS = "$HOME/.local/share:/run/current-system/sw/share:$XDG_DATA_DIRS";
  };
}
