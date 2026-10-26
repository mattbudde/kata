# Katana GO Monitor for Omarchy

An Omarchy shell bar plugin that plays a BOSS Katana GO's stereo USB audio
through the connected computer's speakers or headphones.

Click **型** (kata) in the bar to open the dropdown. It shows USB connection,
monitoring status, input, output, and target latency. Use **Start monitoring**
or **Stop monitoring** to toggle audio. The icon brightens while monitoring.
Connect the amp with a USB data cable first.

## Install

Requires Omarchy's Quickshell shell, Python 3, and `pactl` with PipeWire Pulse
(or PulseAudio). Run:

```sh
git clone https://github.com/mattbudde/kata.git
cd kata
./install
```

Or install directly with Omarchy's plugin manager:

```sh
omarchy plugin add https://github.com/mattbudde/kata --enable
```

The repository must be accessible to your GitHub account while it is private.

The plugin installs under `~/.config/omarchy/plugins/local.katana-go/` and is
enabled beside the audio widget. No administrator access is needed.

## Audio behavior

When enabled, the plugin uses the current default output. If that output is
the Katana itself, it selects an available computer output instead. Select
your preferred speakers/headphones in Omarchy's audio menu before enabling.
To change outputs while monitoring, switch monitoring off and on again.

Only the Katana's real capture source is used, never an output monitor or
computer microphone. The loopback requests 20 ms latency; actual latency
depends on your audio hardware and server. Existing audio volumes and default
devices are preserved. Monitoring is off initially and does not persist across
audio-server restarts. The route can remain active when the widget is disabled;
turn monitoring off before removing the plugin. After unplugging/reconnecting,
click off/on if necessary to recreate the route.

## Command line

```sh
python3 ~/.config/omarchy/plugins/local.katana-go/katana-go.py toggle
# Other commands: status, on, off. Output is JSON.
```

## Remove

```sh
python3 ~/.config/omarchy/plugins/local.katana-go/katana-go.py off
omarchy plugin remove local.katana-go --yes
```

## Validation

```sh
./check
```

Six tests cover capture-source selection, isolation from unrelated loopbacks,
missing USB hardware, avoiding playback into the amp, and route status. Live routing was
also tested on a connected BOSS Katana GO using PipeWire.
