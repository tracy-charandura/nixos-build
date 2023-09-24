{ config, pkgs, ... }:

let
  # Import user-specific configuration
  userConfig = import ./user-config.nix;

in
{
  # General System Configurations
  system.stateVersion = "23.05"; # System version specification
  nixpkgs.config.allowUnfree = true; # Enable non-free packages
  time.timeZone = "Europe/London"; # Set timezone

  # Hardware and Boot Configurations
  imports = [ ./hardware-configuration.nix ]; # Include hardware-specific configurations
  boot = {
    loader = { 
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_6_4; # Specify the Linux kernel package version
  };
  
  # Disable all power management related services
  systemd.targets = {
    suspend = {};
    hibernate = {};
    hybrid-sleep = {};
    sleep = {};
  };

  # User Configurations
  users.users.${userConfig.username} = {
    isNormalUser = true;
    home = userConfig.homeDirectory;
    shell = pkgs.zsh; # Setting Zsh as the default shell
    extraGroups = [ "wheel" "networkmanager" ]; # Adding the user to groups
  };

  # Software and Package Configurations
  environment.systemPackages = with pkgs; [ # List of packages to be globally installed
    alacritty neovim google-chrome wget docker wob libfido2 gh swappy swaylock-effects
    nodejs python3 python3Packages.pip shellcheck wdisplays git blueman brightnessctl hyprpaper
    home-manager pavucontrol alsa-utils grim bluez vscode gnome.gnome-boxes shfmt mako slurp 
    wl-clipboard unzip statix nixpkgs-fmt neofetch rofi-wayland libnotify waybar
    (emacsWithPackagesFromUsePackage {
      config = ./emacs/init.el;
      defaultInitFile = true;
      alwaysEnsure = true;
      alwaysTangle = true;
      package = pkgs.emacs-pgtk;
      extraEmacsPackages = epkgs: [
        epkgs.use-package epkgs.terraform-mode epkgs.flycheck epkgs.flycheck-inline
        epkgs.dockerfile-mode epkgs.nix-mode epkgs.blacken epkgs.treemacs
        epkgs.treemacs-all-the-icons epkgs.solarized-theme epkgs.helm epkgs.vterm
      ];
    })
  ];
  virtualisation.docker.enable = true; # Enable Docker
  programs.dconf.enable = true; # Enable DConf for configuration management
  programs.zsh.enable = true; # Enable ZSH for the system
  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = "https://github.com/nix-community/emacs-overlay/archive/master.tar.gz";
      sha256 = "sha256:0rjp59xqw8p5mi4dgm2mldn2rqx5a1pmimyvs5y5cnm9ihbyjnmv";
    }))
  ];

  # Sound and Media Configurations
  sound.enable = true; # Enable sound support
  security.rtkit.enable = true; # Enable RTKit for low-latency audio
  services = {
    pipewire = { # Enable PipeWire for audio support
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true; # If you want to enable 32 bit application support
      };
      jack = {
        enable = true; 
      };
      pulse.enable = true; # This enables the PulseAudio compatibility modules
    };
    blueman.enable = true; # Blueman service for managing Bluetooth
    fwupd.enable = true; # Enable firmware update
  };

  # Network and Bluetooth Configurations
  networking.networkmanager.enable = true; # Enable NetworkManager for network management
  hardware = {
    bluetooth = {
      enable = true;
      package = pkgs.bluez; # Use the full Bluez package for Bluetooth support
      powerOnBoot = true; # Power on Bluetooth devices at boot
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
    enableAllFirmware = true;
    opengl = {
      enable = true; # Enable OpenGL support
      driSupport = true; # Enable Direct Rendering Infrastructure support
    };
  };
  security.pam.services.swaylock = { allowNullPassword = true; }; # Enable PAM for Swaylock
  xdg.portal = {
    enable = true; # Enable xdg desktop integration
    extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
  };
}
