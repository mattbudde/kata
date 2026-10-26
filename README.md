# Katana GO Monitor for Omarchy

Play a BOSS Katana GO's stereo USB audio through your computer's speakers or
headphones using a small Omarchy bar dropdown.

Click **型** (kata) to view USB connection, monitoring status, input, output,
and target latency. Choose **Start monitoring** or **Stop monitoring**. The
icon brightens while monitoring. **Escape** closes the dropdown, **Enter** or
**Space** activates its monitoring button, and **Tab / Shift+Tab** switches
between available bar panels.

## Requirements

- Omarchy's Quickshell shell with `qs.Ui` components (`BarWidget`,
  `WidgetButton`, `KeyboardPanel`, and `PanelKeyCatcher`). This plugin targets
  the Quattro shell described by the [development guide](https://plugins.omarchy.org/develop.html).
- Python 3 (`python3`), `pactl` with JSON support, and a running PipeWire Pulse
  or compatible PulseAudio server with `module-loopback` support.
- `notify-send` (libnotify) for action-error notifications.
- A USB data cable and a Katana GO exposing a stereo capture source.
- A font fallback that includes the **型** character.

## Install

Install and enable through Omarchy (review the plugin when prompted):

```sh
omarchy plugin add https://github.com/mattbudde/kata.git --enable
```

The repository must be accessible to your GitHub account while it is private.
The plugin ID is `io.github.mattbudde.kata`, with files under
`~/.config/omarchy/plugins/io.github.mattbudde.kata/`.

For local development, clone the repository and run its explicit installer:

```sh
git clone https://github.com/mattbudde/kata.git
cd kata
./install
```

The installer copies this plugin's files, enables it beside the audio widget,
and disables the earlier `local.katana-go` development widget if present.
It preserves that development folder and recognizes its existing audio routes.
Do not run the local installer over a plugin-manager checkout; use
`omarchy plugin update io.github.mattbudde.kata` for git-managed installs.

## Configure and use

Connect the amp via USB. Select your speakers/headphones in Omarchy's audio
menu, open **型**, then choose **Start monitoring**.

```sh
omarchy bar move io.github.mattbudde.kata --section right --before omarchy.audio
omarchy-shell shell summon io.github.mattbudde.kata '{}'
omarchy-shell shell hide io.github.mattbudde.kata
```

There are no plugin-specific settings. When enabled, monitoring uses the
current default output. If that output is the Katana itself, it selects an
available computer output instead. Restart monitoring to apply output changes.

Only the Katana's real capture source is used, never an output monitor or
computer microphone. The loopback requests 20 ms latency; actual latency
depends on hardware and the audio server. Existing volumes and default devices
are preserved. Monitoring starts off and does not persist across audio-server
restarts. After unplugging/reconnecting, stop/start if needed to recreate the
route. A disconnected amp's remaining route can still be stopped.

## Permissions and side effects

Like other Omarchy plugins, this runs unsandboxed with your user permissions
inside the existing shell. It runs a local Python helper and `pactl` to inspect
audio devices and load/unload its own loopback. It uses an advisory lock under
`$XDG_RUNTIME_DIR` to serialize changes and polls status every two seconds.
Action failures can launch `notify-send`. Background polls do not disable or
change the monitoring button.

No administrator access, package installation, background service, remote
build, network request, or second Quickshell process is used at runtime.
Installation changes only this plugin's folder and its placement in Omarchy's
user bar configuration. Audio monitoring can remain active after disabling the
widget or restarting the shell; stop it explicitly before removal.

## Command line

```sh
python3 ~/.config/omarchy/plugins/io.github.mattbudde.kata/katana-go.py toggle
# Other commands: status, on, off. Output is JSON.
```

## Disable or remove

Stop monitoring first, then disable the widget or remove it:

```sh
python3 ~/.config/omarchy/plugins/io.github.mattbudde.kata/katana-go.py off
omarchy plugin disable io.github.mattbudde.kata
# To delete the plugin instead (Omarchy asks for confirmation):
omarchy plugin remove io.github.mattbudde.kata
```

Existing unrelated audio routes are preserved. Omarchy backs up manually
installed plugin folders on removal; git-managed checkouts are deleted.

## Development and validation

```sh
./check
```

Requires the installed Omarchy shell and Qt 6 `qmllint` (on Arch it is available
at `/usr/lib/qt6/bin/qmllint`). The script runs seven Python tests, Python and
shell syntax checks, manifest/layout validation, QML linting against installed
shell imports, and Git whitespace checks. Its temporary QML import namespace
is outside the repository; plugin folders contain no symlinks.

Live USB routing was verified with a Katana GO and PipeWire during initial
development. See [PUBLISHING.md](PUBLISHING.md) for the guide audit and remaining
marketplace steps.

## License

[MIT](LICENSE). BOSS and KATANA GO are names of their respective owners; this
is an independent plugin.
