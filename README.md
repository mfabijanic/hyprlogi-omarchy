# HyprLogi for Omarchy

An [Omarchy](https://omarchy.org/) bar widget for [HyprLogi](https://github.com/mfabijanic/hyprlogi), the daemon
that plays haptic feedback on Logitech mice (MX Master 4) for Hyprland events.

- **Bar icon**: a mouse while haptics run, a crossed-out mouse while they are paused, and an urgent warning when
  the daemon is not running or HyprLogi is not installed. The tooltip names the active profile.
- **Panel**: a switch to pause and resume haptics, the profile list (click to switch, the daemon picks it up at
  once), *Test effects* and *Restart service*.
- **Mouse**: left click opens the panel, middle click pauses or resumes, right click refreshes.
- **Keyboard** (panel open): arrows and Enter, `P` pause/resume, `T` test, `R` refresh.

The widget only runs the `hyprlogi` command (`status --json`, `toggle`, `profile set`, `play`); it needs
HyprLogi 0.3.0 or newer.

## Install

```sh
yay -S hyprlogi                                   # HyprLogi itself
systemctl --user enable --now hyprlogi.service
hyprlogi omarchy install --plugin                 # menu, hooks and this widget
```

or just the widget:

```sh
omarchy plugin add https://github.com/mfabijanic/hyprlogi-omarchy.git --enable
```

The widget lands in the right section of the bar; move it with `omarchy bar move mfabijanic.hyprlogi --section left`.
Its only setting, the refresh interval (default 10 s), is under Setup > Plugins.

## Development

Symlink the checkout into the shell's plugin directory; saving a file reloads it:

```sh
ln -s "$PWD" ~/.config/omarchy/plugins/mfabijanic.hyprlogi
omarchy-shell shell rescanPlugins
omarchy plugin enable mfabijanic.hyprlogi
```

- `omarchy plugin validate .` checks the manifest.
- `node --test tests/` tests the pure logic in `Model.js`.
- `qs log -p /usr/share/omarchy/shell -t 200` shows the shell log (QML errors).

## License

GPL-3.0-or-later, like HyprLogi.
