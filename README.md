# garmin-connect-screens

Custom Connect IQ data fields for the **Garmin Edge Explore 2**, written in [Monkey C](https://developer.garmin.com/connect-iq/overview/).

## Repository layout

```
screens/
└── <screen-name>/
    ├── manifest.xml          # app metadata & target device
    ├── monkey.jungle         # build configuration
    ├── source/               # Monkey C source files (.mc)
    └── resources/
        ├── strings/          # localised strings
        └── properties.xml    # user-configurable settings (optional)
```

Each subdirectory under `screens/` is a self-contained Connect IQ project that can be opened, built, and deployed independently.

## Data screens

| Folder | Description |
|--------|-------------|
| `minimal-7` | Full-screen field: time, timer, 3s power (zone color), speed, cadence, ascent, distance |
| `example-field` | Starter template – displays current speed in km/h |

## Getting started

1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and VS Code extension (or Eclipse plugin).
2. Open a screen folder (e.g. `screens/example-field`) as your project root.
3. Build with `monkeyc` or use the IDE's **Run** action against the Edge Explore 2 simulator.
4. Sideload the generated `.iq` file to your device via Garmin Express or the Connect IQ phone app.

### Linux setup

This repo includes bootstrap scripts for the two Linux distros requested here:

```bash
# Ubuntu
./scripts/setup-ubuntu.sh

# Arch Linux
./scripts/setup-arch.sh
```

What the scripts do:
- install the base OS packages required here (`curl`, `unzip`, `openssl`, Java runtime, etc.)
- install [`connect-iq-sdk-manager`](https://github.com/lindell/connect-iq-sdk-manager-cli)
- add both `~/.local/bin` and the active Connect IQ SDK `bin` directory to your shell startup files
- accept the Garmin SDK agreement interactively
- download and activate Connect IQ SDK `>=8.4.0`
- download device definitions and simulator fonts for every `screens/*/manifest.xml` in this repo

The scripts assume:
- `sudo` is available
- you will complete the Garmin login flow when `connect-iq-sdk-manager login` prompts for it
- you will generate or provide your own `developer_key.der` for signed builds

### Build a screen

Both current screens target `edgeexplore2`, so a local build looks like this:

```bash
mkdir -p screens/example-field/bin

monkeyc \
  -f screens/example-field/monkey.jungle \
  -o screens/example-field/bin/example-field-edgeexplore2.prg \
  -y developer_key.der \
  -d edgeexplore2 \
  -r \
  -w
```

To build the other screen:

```bash
mkdir -p screens/minimal-7/bin

monkeyc \
  -f screens/minimal-7/monkey.jungle \
  -o screens/minimal-7/bin/minimal-7-edgeexplore2.prg \
  -y developer_key.der \
  -d edgeexplore2 \
  -r \
  -w
```

Notes:
- `-f` points to the screen's `monkey.jungle`
- `-o` writes the signed output `.prg`
- `-y` is your `developer_key.der`
- `-d` must match the device id in that screen's `manifest.xml`
- `-r` builds a release artifact
- `-w` enables warnings

If `monkeyc` is not found, load the SDK bin directory into your shell first:

```bash
export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
```

### Run in the simulator

To verify that a screen actually runs, start the Connect IQ simulator first:

```bash
export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
simulator
```

Then, in a second terminal, push the compiled `.prg` to the running simulator:

```bash
monkeydo screens/example-field/bin/example-field-edgeexplore2.prg edgeexplore2
```

For `minimal-7`:

```bash
monkeydo screens/minimal-7/bin/minimal-7-edgeexplore2.prg edgeexplore2
```

Notes:
- `monkeydo` requires the simulator to already be running
- the device id must match the screen's `manifest.xml`
- if the screen does not launch, rebuild it first with `monkeyc` and check the simulator logs/output

If the simulator fails with a missing font file under `~/.Garmin/ConnectIQ/Fonts`, download the device assets again with fonts enabled:

```bash
connect-iq-sdk-manager device download \
  --manifest screens/example-field/manifest.xml \
  --include-fonts
```

## Releases

Each screen is released independently using a scoped version tag:

```bash
git tag screens/<screen-name>/v1.0.0
git push origin screens/<screen-name>/v1.0.0
```

The CI workflow (`.github/workflows/release.yml`) picks up the tag, compiles the screen
with `monkeyc`, and publishes the `.iq` file as a GitHub release.

**Required setup (once):**
- `CIQ_SDK_URL` — repository variable pointing to the Linux Connect IQ SDK zip.
- `CIQ_DEVELOPER_KEY` — repository secret containing `base64 developer_key.der`.

See the workflow file for key generation instructions.

## Adding a new screen

1. Copy `screens/example-field` to a new folder under `screens/`.
2. Generate a fresh UUID for the `id` attribute in `manifest.xml`.
3. Rename the entry class in `manifest.xml` and `source/` to match your new screen.
4. Update `resources/strings/strings.xml` with the new app name.
