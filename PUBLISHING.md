# Publishing checklist

Audited on 2026-10-26 against the marketplace
[development guide](https://plugins.omarchy.org/develop.html),
[publishing guide](https://plugins.omarchy.org/publish.html), and the official
[submission form](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/.github/ISSUE_TEMPLATE/submit-plugin.yml).

## Repository and runtime

- Permanent ID: `io.github.mattbudde.kata`; consistent in the manifest, QML,
  helper, installer, and docs. Older development routes remain controllable.
- Root manifest declares schema, semantic version, author, description, MIT
  license, bar-widget kind, and a safe relative entry point.
- Shared `BarWidget`, `WidgetButton`, `KeyboardPanel`, `PanelKeyCatcher`,
  button, and separator components; open/close/toggle and popout lifecycle.
- Theme spacing, font, and palette tokens; no second shell process or root
  privileges. Dependencies and side effects documented in README.
- README includes install, use, configuration, update, disable, and removal.
- Root LICENSE; no symlinks. Preview image is optional and currently omitted.
- `./check` covers manifest/layout, Python tests, syntax, QML lint, whitespace.

## Local validation completed

- Seven unit tests, Python/shell syntax, manifest validation, QML lint, and
  whitespace checks pass.
- Shell summon/hide, Escape dismissal, disable/re-enable, shell restart,
  and removal/reinstallation verified on the installed desktop.
- Initial USB route creation/removal verified with the connected Katana GO.
  At audit time the amp was disconnected, so the new ID's live route creation
  was not repeated; route ownership and legacy cleanup are unit-tested.

## Marketplace submission (pending)

The repository is currently private. The owner must approve making it public
before marketplace submission. No listing has been submitted.

Ready-to-use listing details:

- Repository: https://github.com/mattbudde/kata
- Category: Hardware
- Tags: Bar, Media, Quickshell
- Maintainer notes: Stereo BOSS Katana GO USB monitoring through a computer
  audio output. Requires the Quattro shell, Python 3, pactl with JSON support,
  a compatible PulseAudio/PipeWire Pulse server, and libnotify. No root access,
  downloads, remote builds, or extra services. Stop monitoring before removal.

After visibility approval, verify installation from a fresh git checkout,
then use the marketplace submission form. The owner must confirm ownership or
permission to submit the plugin and assets, and acknowledge that marketplace
approval concerns listing rather than a security review.
