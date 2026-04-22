# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
  enable = true;
  efiSupport = true;
  device = "nodev"; # important for UEFI
};

boot.loader.timeout = 1;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = "nixosbtw"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain

  #BROWSER
  xdg.mime = {
  enable = true;
  defaultApplications = {
    "text/html" = "chromium.desktop";
    "x-scheme-handler/http" = "chromium.desktop";
    "x-scheme-handler/https" = "chromium.desktop";
    "x-scheme-handler/about" = "chromium.desktop";
    "x-scheme-handler/unknown" = "chromium.desktop";
  };
};

#DISK
fileSystems."/mnt/storage" = {
    device = "/dev/disk/by-uuid/32b9b16a-7fed-446e-ab27-0119977e2391";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };

  #UDEV
  services.udev.extraRules = ''
  # HyperX Cloud III Wireless (HP Vendor ID 03f0)
  SUBSYSTEM=="usb", ATTR{idVendor}=="03f0", ATTR{idProduct}=="05b7", MODE="0660", GROUP="input"
  SUBSYSTEM=="hidraw", ATTRS{idVendor}=="03f0", ATTRS{idProduct}=="05b7", MODE="0660", GROUP="input"
'';


  #HARDWARE UINPUT
  hardware.uinput.enable = true;

  #OPENRAZER
  hardware.openrazer.enable = true;

  #NIX LD
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libGL
    glib
    libX11
    libXext
    libXcursor
    libXrandr
    libXi
    fontconfig
    freetype
  ];

  # Enable networking
  networking.networkmanager.enable = true;
  networking.extraHosts = ''
  127.0.0.1 ubuntu.com
  127.0.0.1 www.ubuntu.com
  127.0.0.1 archive.ubuntu.com
  127.0.0.1 security.ubuntu.com
  '';

  # Set your time zone.
  time.timeZone = "Europe/Prague";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

#polkit
security.polkit.enable = true;

#sideloading
services.gvfs.enable = true;
services.usbmuxd.enable = true;

#flatpak
services.flatpak.enable = true;

#FONTS
fonts.packages = with pkgs; [
  nerd-fonts.jetbrains-mono
  noto-fonts
  noto-fonts-cjk-sans
];


  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = false;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.nrxg = {
    isNormalUser = true;
    description = "nrxg";
    extraGroups = [ "networkmanager" "wheel" "plugdev" "openrazer" "audio" "input"];
    shell = pkgs.fish;
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  #THUNAR
    programs.thunar = {
    enable = true;
    plugins = with pkgs.xfce; [
      pkgs.thunar-archive-plugin
      pkgs.thunar-volman #USB AUTOMOUNT
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
  	slurp
  	mesa-demos
  	btop
	neovim
	vesktop
	fish
	kitty
	fastfetch
	glew
	libGLU
	steam-run
	freeglut
	waybar
	rofi
	swaynotificationcenter
	mesa
	git
	perl
	wget
	gcc
	perl
	sassc
	wine64Packages.stable
	winetricks
	udiskie
	awww
	libimobiledevice
	usbmuxd
	wl-clipboard
	ifuse
	gvfs
	hyprlock
	pavucontrol
	matugen
	wlogout
	cava
	kdePackages.kate
	unzip
	unrar
	flatpak
	grim
	imagemagick
	feh
	libglvnd
 	xorg-server
  	xwayland
	gnome-themes-extra
	glib
	gsettings-desktop-schemas
	nvibrant
	chromium
	adwaita-icon-theme
	qt6Packages.qt6ct
	libsForQt5.qt5ct
	adwaita-qt
	libX11
	libXcursor
	libXrandr
	libXi
	ani-cli
	peaclock
	openrazer-daemon
	razergenie
	usbutils
	lavat
	playerctl
	mapscii
	file-roller
	zip
	rar
	manga-tui	
	wev
	libGL
	SDL2
	SDL2_image
	SDL2_mixer
	SDL2_ttf
	openssl
	fzf
	mpv
	jq
	obs-studio
	llama-cpp
	ollama


	#UPSCAYL
	(symlinkJoin {
      name = "upscayl-wrapped";
      paths = [ upscayl ];
      nativeBuildInputs = [ makeWrapper ]; # Use nativeBuildInputs for the wrapper tool
      postBuild = ''
        wrapProgram $out/bin/upscayl \
          --add-flags "--disable-gpu-sandbox" \
          --add-flags "--disable-features=UseOzonePlatform" \
          --add-flags "--ozone-platform=x11"
      '';
    })
  ];

#FLAKES
nix.settings.experimental-features = [ "nix-command" "flakes" ];

#fish
programs.fish = {
	enable = true;
	shellAliases = {
	ff = "fastfetch";
     };
  };

##PORTALS
xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-wlr
    ];
  };

#HYPRLAND
programs.hyprland = {
  enable = true;
  xwayland.enable = true;
};

#XWAYLAND ENABLE
programs.xwayland.enable = true;

## NVIDIA
services.xserver.videoDrivers = [ "nvidia" ];

hardware.graphics = {
  enable = true;
  enable32Bit = true;
  extraPackages = with pkgs; [
	vulkan-loader
	vulkan-validation-layers
  ];
  extraPackages32 = with pkgs.pkgsi686Linux; [
  vulkan-loader
  ];
};

hardware.nvidia = {
  modesetting.enable = true;
  open = false;
  nvidiaSettings = true;
  package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
};

#ENVIROMENT
environment.sessionVariables = {
  NIXOS_OZONE_WL = "1";
  MOZ_ENABLE_WAYLAND = "1";
  LIBVA_DRIVER_NAME = "nvidia";
  XDG_SESSION_TYPE = "wayland";
  GBM_BACKEND = "nvidia-drm";
  __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  CURSOR_FLAGS = "--no-hardware-cursors"; 
  #SDL_VIDEODRIVER = "wayland,x11";
};

#DBUS
services.dbus.packages = [ pkgs.gsettings-desktop-schemas ];


  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
