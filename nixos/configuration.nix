{ config, lib, pkgs, ... }:
let
  home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/master.tar.gz";
in
{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      (import "${home-manager}/nixos")
    ];
  
  # Home Manager options
  home-manager = {
	useUserPackages = true;
	useGlobalPkgs = true;
        backupFileExtension = "backup";
        users.aryu = ./home.nix;
  };

  # Use systemd boot as EFI boot loader
  boot.loader.systemd-boot.enable = true;

  # Enable efi variables
  boot.loader.efi.canTouchEfiVariables = true;

  # Support for ntfs filesystems
  boot.supportedFilesystems = [ "ntfs" ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Optimize storage weekly instead of during active package builds
  nix.settings.auto-optimise-store = false;
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };

  # Automatically clean up old generations to prevent Nix store bloat
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 6d";
  };

  # Hardware options
  hardware.graphics = {
  enable = true;
  extraPackages = with pkgs; [
    intel-media-driver # Primary VA-API driver for 12th Gen Intel Graphics (iHD)
    vpl-gpu-rt         # Replaces legacy media-sdk for modern Quick Sync decoding
    ];
  };
  
  boot.kernelParams = ["i915.enable_guc=3"]; # Force the kernel to load GuC/HuC firmware
 
  networking.hostName = "nixos-btw"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;
  
  # allow unfree software
  nixpkgs.config.allowUnfree = true;

  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties aka locale settings
  i18n.defaultLocale = "en_US.UTF-8";

  # Enable sound.
  services.pipewire = {
     enable = true;
     pulse.enable = true;
   };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.aryu = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
     packages = with pkgs; [
       tree
     ];
   };

  # install programs
    programs = {
      firefox.enable = true;
      steam.enable = true;
      hyprland.enable = true; # enable window manager
    };
    
    # enable display manager
   services.displayManager = {
  	enable = true;
  	ly = {
    	enable = true;
   	 settings = {
      	 # Enable animations
         animate = true;
      	 animation = "gameoflife"; 
	 gameoflife_entropy_interval = 10;
      	 border_fg = "0x0000FFFF";
	 main_fg = "0x00FFFFFF";

         hide_borders = true;
         bigclock = true;
	 blank_box = true;
      		};
  	};
  };
  
   # List packages installed in system profile aka just simple binaries like cmd tools
   environment.systemPackages = with pkgs; [
    (import home-manager { inherit pkgs; }).home-manager
     yazi
     libva-utils
     pkgs.openjdk21
     pkgs.steam-run
     pkgs.vesktop
     ];

 # Environment variables
  environment.sessionVariables = {
   LIBVA_DRIVER_NAME = "iHD";
   GTK_THEME = "Breeze-Dark";
   };
  
  # fonts
  fonts.packages = with pkgs; [
  noto-fonts
  noto-fonts-cjk-sans
  noto-fonts-color-emoji
  nerd-fonts.jetbrains-mono
  ];

  # firewall configs
  networking.firewall.enable = true; 

  # current system version
  system.stateVersion = "26.05"; 
  
  # enable dbus
  services.dbus.enable = true;
  xdg.portal = {
  	enable = true;
  	extraPortals = [ 
    	pkgs.xdg-desktop-portal-hyprland 
    	pkgs.xdg-desktop-portal-gtk     	
	];
  	config.common.default = "*";
  };

  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
  [Settings]
  gtk-theme-name=Breeze-Dark
  gtk-application-prefer-dark-theme=1
  '';

  environment.etc."xdg/gtk-4.0/settings.ini".text = ''
  [Settings]
  gtk-theme-name=Breeze-Dark
  gtk-application-prefer-dark-theme=1
  '';
}
