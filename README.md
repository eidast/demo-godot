# GameOfLife2D

A Godot 4 tribute to [Conway's Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life), with a mobile-oriented welcome flow, language settings, and an Android testing/export baseline.

## Requirements

- [Godot 4.x](https://godotengine.org/download/) (tested with 4.6.x).

## Current state

The project currently includes:

- A mobile-friendly welcome screen.
- A settings screen with language selection.
- A main gameplay scene for the cellular automaton.
- A dynamic board that keeps cell size stable while adapting rows and columns to the available viewport space.
- A random live starting state when gameplay opens.
- A hybrid retro typography setup:
  - `Tiny5` for the main title treatment
  - `VT323` for readable body copy, buttons, and the in-game HUD
- Local Android export support and emulator testing.

## Running the project

### Option A: from the Godot editor

1. Open **Godot**.
2. In the **Project Manager**:
   - Click **Import** and choose the project directory that contains `project.godot`, or
   - Click **Scan** and add the parent directory so the project appears in the list.
3. Select **GameOfLife2D** and click **Edit**.
4. Run the game with one of the following:
   - `F5`
   - the **Play** button in the top-right corner
   - **Project -> Run Project**

Godot will open a separate game window. That window is the actual running game.

### What you should see

- First, a welcome screen with a retro pixel-art presentation.
- Then, after starting the game, a visible random board that starts simulating immediately.
- A HUD at the top with controls for play/pause, FUN mode, randomizing, changing speed, and returning to the menu.

### Quick verification

1. Press **Start** on the welcome screen.
2. Confirm that the board shows live cells immediately.
3. Press **Play** or **Pause** to control continuous simulation.
4. Use **Clear** to empty the board or **Random** to repopulate it.
5. Confirm that the board reacts to touch input.

To close the game window, close that window directly or return to the editor and press **Stop** (`F8`).

### Option B: from the terminal

If `godot` is available in your `PATH`, you can open the project like this:

```bash
cd /path/to/demo-godot
godot --path .
```

This opens the editor with the project loaded. Press `F5` to run the game.

## Controls

- **Left click / touch**: toggle or paint cells.
- **Play / Pause**: run or stop continuous simulation.
- **FUN / Random**: kick off continuous high-speed random play, or fill the board randomly.
- **Menu**: return to the welcome screen.
- Keyboard shortcuts:
  - `Space`: play/pause
  - `N`: step once
  - `C`: clear
  - `R`: randomize

## Board model

The board implementation follows these principles:

- Cell size remains visually stable.
- Row and column counts are derived from the available viewport area.
- The board rebuilds when the viewport size changes.
- Simulation uses two buffers:
  - `current_grid` for the current generation
  - `next_grid` for the next generation calculation
- Startup uses a random seeded board with a fallback to a deterministic pattern only if a random seed ever ends up empty.

This makes debugging easier because rendering issues and simulation issues can be tested with deterministic patterns.

## Android

The project has been tested on both an Android emulator and a real Android phone.

Important notes:

- The project now targets the `mobile` renderer for real Android devices.
- The current handheld orientation is portrait.
- A local helper script exists at `scripts/ExportAndroid.gd` for generating a debug APK from the Godot editor context.
- Safe-area handling is intentionally light:
  - backgrounds and large panels stay close to edge-to-edge
  - controls and important text get a modest top/cutout offset
  - left/right protection is minimal to avoid wasting screen width on modern hole-punch phones
- Android launcher flows are explicit to avoid accidental renderer mismatches:
  - `run_android_emulator.sh` always targets an emulator and exports with `gl_compatibility`
  - `run_android_phone.sh` always targets a real phone and exports with `mobile`
  - both restore `project.godot` renderer settings when they finish

Local debug export command:

```bash
godot --headless --editor --path . --script res://scripts/ExportAndroid.gd
```

The resulting APK is written to:

```bash
build/android/demo-godot-debug.apk
```

To export, install, and launch the debug build on a running Android emulator:

```bash
./run_android_emulator.sh
```

You can also pass a specific emulator serial:

```bash
./run_android_emulator.sh emulator-5554
```

To do the same on a connected Android phone:

```bash
./run_android_phone.sh
```

Or target a specific phone serial:

```bash
./run_android_phone.sh R5CWC44TCJR
```

The shared deployment implementation lives in:

```bash
scripts/run_android_target.sh
```

## Testing

The test strategy follows a pragmatic Godot approach:

- Keep Conway rule validation deterministic and independent from rendering.
- Run fast headless tests from the command line.
- Add a lightweight scene smoke test to confirm the playable scene still boots, seeds the board, and starts simulating.

This repository includes:

- `scripts/GameOfLifeBoard.gd` for pure simulation-rule tests.
- `tests/test_runner.gd` for headless test execution.
- `.github/workflows/godot-tests.yml` for CI validation.

Run the tests locally with:

```bash
godot --headless --path . --script res://tests/test_runner.gd
```

What the tests currently cover:

- Conway rules for classic patterns such as `blinker` and `block`.
- Demo pattern seeding.
- Scene startup smoke checks for `main.tscn`.
- Safe-area inset math.
- Language defaults and translation switching.

## Release pipeline

The repository follows a two-phase Android release flow:

1. Build a signed Android App Bundle (`.aab`) and upload it as a GitHub Actions artifact.
2. Publish that artifact to Google Play in a separate workflow.

This separation keeps bundle generation and store publishing independent, which is safer and easier to audit.

### Phase 1: signed bundle build

The first phase is implemented in:

- `.github/workflows/android-build-release-bundle.yml`

That workflow:

- downloads Godot 4.6.2 and Android export templates
- configures isolated Godot editor settings for CI
- materializes the release keystore from GitHub Secrets
- updates the Android release preset with package name and version values
- exports a signed `.aab`
- stores the bundle and release metadata as a GitHub Actions artifact

### Phase 2: publish an existing bundle

The publish phase is implemented in:

- `.github/workflows/android-publish-google-play.yml`

That workflow:

- downloads the artifact generated by phase 1
- reads the stored release metadata
- validates the release policy
- authenticates to Google Cloud / Google Play
- uploads the `.aab` to the requested Google Play track

The upload logic lives in:

- `scripts/release/upload_play_bundle.py`

### Required GitHub Secrets

The bundle build workflow expects these secrets:

- `ANDROID_UPLOAD_KEYSTORE_BASE64`
- `ANDROID_UPLOAD_KEYSTORE_PASSWORD`
- `ANDROID_UPLOAD_KEY_ALIAS`
- `ANDROID_UPLOAD_KEY_PASSWORD`

Important: for Godot's Android release export, the keystore password and the key password must currently match. The workflow validates this and fails early if they differ.

### Required Google Play configuration

For the publish workflow, configure one of these authentication paths:

1. Workload Identity Federation
   - `GCP_WORKLOAD_IDENTITY_PROVIDER`
   - `GCP_SERVICE_ACCOUNT_EMAIL`

2. Service account JSON
   - `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
   - `GCP_SERVICE_ACCOUNT_EMAIL`

The service account must have access to the Google Play Console app and permission to manage releases through the Android Publisher API.

### Suggested release flow

1. Run `Build Android Release Bundle`.
2. Verify the generated artifact and release metadata.
3. Run `Publish Existing Bundle To Google Play`.
4. Start with the `internal` track and `draft` status until the release setup is fully trusted.

## Structure

- `project.godot` - project configuration.
- `AGENTS.md` - project-specific operating notes for future agents.
- `welcome.tscn` - welcome screen and app entry point.
- `settings.tscn` - language settings screen.
- `main.tscn` - gameplay scene (`Node2D` + `Timer`).
- `scripts/GameSettings.gd` - global language state and translated UI text.
- `scripts/GameOfLife.gd` - board state, rules, drawing, input, and HUD.
- `scripts/WelcomeScreen.gd` - navigation from the welcome screen to gameplay or settings.
- `scripts/SettingsScreen.gd` - language selection and navigation back to the main menu.
- `scripts/SafeArea.gd` - safe-area inset helper used by the mobile screens and HUD.
- `scripts/ExportAndroid.gd` - local debug APK export helper for Android testing.
- `scripts/run_android_target.sh` - shared Android deploy script used by the explicit emulator/phone wrappers.
- `scripts/release/` - release pipeline helper scripts for CI bundle generation and Play publishing.
- `run_android_emulator.sh` - explicit emulator deploy command.
- `run_android_phone.sh` - explicit real-phone deploy command.
