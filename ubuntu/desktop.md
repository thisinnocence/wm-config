# Ubuntu System Configuration

This file records user-level and system-level settings applied on this Ubuntu GNOME Wayland desktop.

## System Context

```text
OS: Ubuntu 26.04 LTS
Desktop session: GNOME Wayland
User: michael
```

## Ubuntu Dock

The Ubuntu Dock is configured to sit at the bottom of the screen, use a centered macOS-like layout, hide intelligently, and use a more dock-like click action.

```bash
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock intellihide true
gsettings set org.gnome.shell.extensions.dash-to-dock click-action minimize-or-previews
```

### Setting Details

#### `extend-height`

Controls whether the dock stretches across the full side of the screen.  Meaning:

- `true`: dock extends along the full screen edge
- `false`: dock only takes the space needed by its icons, giving a centered dock appearance

#### `dock-fixed`

Controls whether the dock behaves like a normal persistent dock. Meaning:

- `true`: dock is available as a normal dock
- `false`: dock is more dependent on hide/show behavior

#### `intellihide`

Controls whether the dock hides when a window overlaps its screen area. Meaning:

- `true`: dock stays visible when it has space, and hides when windows would cover it
- `false`: dock does not use intelligent hiding

#### `click-action`

Controls what happens when clicking an app icon in the dock.

Current value: `bash minimize-or-previews`, Meaning:

- If the app has one active window, clicking can minimize it
- If the app has multiple windows, clicking can show window previews
- This feels closer to macOS Dock behavior than the Ubuntu default

### Check Values

Run these commands to verify the current dock configuration:

```bash
gsettings get org.gnome.shell.extensions.dash-to-dock dock-position
gsettings get org.gnome.shell.extensions.dash-to-dock extend-height
gsettings get org.gnome.shell.extensions.dash-to-dock dock-fixed
gsettings get org.gnome.shell.extensions.dash-to-dock intellihide
gsettings get org.gnome.shell.extensions.dash-to-dock click-action
```

### Restore Ubuntu Default Style

To move the dock back to the left side and make it full height:

```bash
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position LEFT
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height true
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings reset org.gnome.shell.extensions.dash-to-dock intellihide
gsettings reset org.gnome.shell.extensions.dash-to-dock click-action
```

### Refresh GNOME Shell

If the dock does not update immediately:

- On Wayland: log out and log back in

## Zsh

Powerlevel10k is used as the `Oh My Zsh` theme.

Plugin functions:

- `git`: Oh My Zsh Git aliases and Git completion helpers
- `zsh-autosuggestions`: shows gray command suggestions while typing, based on history and completions
- `zsh-syntax-highlighting`: highlights valid and invalid shell syntax while typing

Reload shell after changes: `exec zsh`

