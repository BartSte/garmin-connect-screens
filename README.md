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
