# garmin-connect-fields

Custom Connect IQ data fields for the **Garmin Edge Explore 2**, written in [Monkey C](https://developer.garmin.com/connect-iq/overview/).

## Repository layout

```
fields/
└── <field-name>/
    ├── manifest.xml          # app metadata & target device
    ├── monkey.jungle         # build configuration
    ├── source/               # Monkey C source files (.mc)
    └── resources/
        ├── strings/          # localised strings
        └── properties.xml    # user-configurable settings (optional)
```

Each subdirectory under `fields/` is a self-contained Connect IQ project that can be opened, built, and deployed independently.

## Data fields

| Folder | Description |
|--------|-------------|
| `minimal-7` | Full-screen field: time, timer, 3s power (zone color), speed, cadence, ascent, distance |
| `example-field` | Starter template – displays current speed in km/h |

## Getting started

1. Install the [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) and VS Code extension (or Eclipse plugin).
2. Open a field folder (e.g. `fields/example-field`) as your project root.
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
- download device definitions and simulator fonts for every `fields/*/manifest.xml` in this repo

The scripts assume:
- `sudo` is available
- you will complete the Garmin login flow when `connect-iq-sdk-manager login` prompts for it
- you will generate or provide your own `developer_key.der` for signed builds

### Build a field

Both current fields target `edgeexplore2`, so a local build looks like this:

```bash
mkdir -p fields/example-field/bin

monkeyc \
  -f fields/example-field/monkey.jungle \
  -o fields/example-field/bin/example-field-edgeexplore2.prg \
  -y developer_key.der \
  -d edgeexplore2 \
  -r \
  -w
```

To build the other field:

```bash
mkdir -p fields/minimal-7/bin

monkeyc \
  -f fields/minimal-7/monkey.jungle \
  -o fields/minimal-7/bin/minimal-7-edgeexplore2.prg \
  -y developer_key.der \
  -d edgeexplore2 \
  -r \
  -w
```

Notes:
- `-f` points to the field's `monkey.jungle`
- `-o` writes the signed output `.prg`
- `-y` is your `developer_key.der`
- `-d` must match the device id in that field's `manifest.xml`
- `-r` builds a release artifact
- `-w` enables warnings

If `monkeyc` is not found, load the SDK bin directory into your shell first:

```bash
export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
```

### Run in the simulator

To verify that a field actually runs, start the Connect IQ simulator first:

```bash
export PATH="$(connect-iq-sdk-manager sdk current-path --bin):$PATH"
simulator
```

Then, in a second terminal, push the compiled `.prg` to the running simulator:

```bash
monkeydo fields/example-field/bin/example-field-edgeexplore2.prg edgeexplore2
```

For `minimal-7`:

```bash
monkeydo fields/minimal-7/bin/minimal-7-edgeexplore2.prg edgeexplore2
```

Notes:
- `monkeydo` requires the simulator to already be running
- the device id must match the field's `manifest.xml`
- if the field does not launch, rebuild it first with `monkeyc` and check the simulator logs/output

If the simulator fails with a missing font file under `~/.Garmin/ConnectIQ/Fonts`, download the device assets again with fonts enabled:

```bash
connect-iq-sdk-manager device download \
  --manifest fields/example-field/manifest.xml \
  --include-fonts
```

## Releases

Each field is released independently using a scoped version tag:

```bash
git tag fields/<field-name>/v1.0.0
git push origin fields/<field-name>/v1.0.0
```

The CI workflow (`.github/workflows/release.yml`) picks up the tag, compiles the field
with `monkeyc`, and publishes the `.iq` file as a GitHub release.

**Required setup (once):**
- `CIQ_SDK_URL` — repository variable pointing to the Linux Connect IQ SDK zip.
- `CIQ_DEVELOPER_KEY` — repository secret containing `base64 developer_key.der`.

See the workflow file for key generation instructions.

## Adding a new field

1. Copy `fields/example-field` to a new folder under `fields/`.
2. Generate a fresh UUID for the `id` attribute in `manifest.xml`.
3. Rename the entry class in `manifest.xml` and `source/` to match your new field.
4. Update `resources/strings/strings.xml` with the new app name.
