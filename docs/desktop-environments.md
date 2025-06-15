# Desktop Environments

This NixOS configuration supports multiple desktop environments that can be easily enabled or disabled.

## Available Desktop Environments

### Traditional Desktop Environments
- **GNOME**: Modern desktop environment with Wayland support
- **KDE Plasma**: Feature-rich desktop environment  
- **Cinnamon**: Traditional desktop based on GNOME technologies
- **Pantheon**: Elementary OS desktop environment
- **COSMIC**: System76's new Rust-based desktop environment

### Wayland Window Managers
- **Sway**: i3-compatible Wayland compositor
- **Hyprland**: Modern, highly customizable Wayland compositor

## Configuration

Desktop environments are configured in your host configuration file (e.g., `hosts/framework-13/default.nix`):

```nix
components = {
  desktop = {
    cinnamon.enable = false;
    cosmic.enable = false;
    gnome.enable = false;
    hyprland.enable = true;    # Enable Hyprland
    pantheon.enable = false;
    plasma.enable = false;
    sway.enable = false;       # Enable Sway
  };
  
  display = {
    gdm.enable = false;
    lightdm.enable = false;
    sddm.enable = false;
    cosmic-greeter.enable = false;
    greetd.enable = true;      # Use greetd for Wayland compositors
  };
};
```

## Important Notes

- **Only enable one desktop environment at a time** to avoid conflicts during builds
- Wayland compositors (Sway, Hyprland) provide better performance and security
- Traditional desktop environments (GNOME, Plasma, etc.) may be more familiar to new users

## Sway Configuration

Sway includes:
- Waybar status bar
- Wofi application launcher
- Foot terminal
- Screenshot tools (grim/slurp)
- Screen locking (swaylock)
- Idle management (swayidle)

### Default Keybindings (Sway)
- `Super + Return`: Open terminal
- `Super + D`: Application launcher
- `Super + Shift + Q`: Kill active window
- `Print`: Screenshot
- `Shift + Print`: Screenshot selection

## Hyprland Configuration

Hyprland includes:
- Waybar status bar
- Wofi/Rofi application launcher
- Foot/Kitty terminal options
- Screenshot tools (grim/slurp)
- Hyprpaper wallpaper manager
- Mako notification daemon

### Default Keybindings (Hyprland)
- `Super + Return`: Open terminal
- `Super + D`: Application launcher
- `Super + Q`: Kill active window
- `Super + M`: Exit Hyprland
- `Print`: Screenshot
- `Shift + Print`: Screenshot selection
## Display Managers

Display managers handle user login and session management. The configuration includes separate display manager options:

### Available Display Managers
- **GDM**: GNOME Display Manager (best for GNOME)
- **LightDM**: Lightweight display manager (good for traditional desktops)
- **SDDM**: Simple Desktop Display Manager (best for KDE Plasma)
- **COSMIC Greeter**: System76's display manager for COSMIC desktop
- **greetd**: Minimal display manager for Wayland compositors (Sway, Hyprland)

### Display Manager Configuration

Configure display managers in the `components.display` section:

```nix
components.display = {
  gdm.enable = false;           # For GNOME
  lightdm.enable = false;       # For traditional desktops
  sddm.enable = false;          # For KDE Plasma
  cosmic-greeter.enable = true; # For COSMIC desktop
  greetd.enable = false;        # For Sway/Hyprland
};
```

### Recommended Combinations

- **COSMIC Desktop**: Use `cosmic-greeter.enable = true`
- **Sway/Hyprland**: Use `greetd.enable = true`
- **GNOME**: Use `gdm.enable = true`
- **KDE Plasma**: Use `sddm.enable = true`
- **Other desktops**: Use `lightdm.enable = true`

**Important**: Only enable one display manager at a time to avoid conflicts.

## User Configuration

Home Manager configurations for Sway and Hyprland can be enabled in user configurations:

```nix
home-manager.features.desktop = {
  sway.enable = true;       # Enable Sway user config
  hyprland.enable = true;   # Enable Hyprland user config
};
```

## Switching Desktop Environments

1. Edit your host configuration file
2. Disable the current desktop environment
3. Enable the desired desktop environment
4. Rebuild your system: `sudo nixos-rebuild switch`
5. Restart your session or reboot

## Troubleshooting

- If you encounter conflicts, ensure only one desktop environment is enabled
- For Wayland issues, check that `XDG_SESSION_TYPE=wayland` is set
- Graphics drivers may need to be configured for optimal Wayland performance