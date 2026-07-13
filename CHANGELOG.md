# Changelog

All notable changes to this project are documented here.
The format is based on [Keep a Changelog](https://keepachangelog.com/),
and this project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### MetaGen

- **Added `metagen/Clean Adobe filenames.bat`** to fix Adobe Stock's bulk-CSV metadata matcher
  silently skipping filenames that contain `[ ]` (common in Adobe Firefly exports like
  `Firefly_---[Wildlife portrait] ... .jpeg`). Unlike the Vecteezy case below, Adobe keeps the
  uploaded filename exactly as-is, so a CSV-only fix can't help — the tool renames the image
  files (stripping the `[...]` segment) and patches the CSV's Filename column with the same
  transform so they stay matched. Drag a folder onto the `.bat`; it previews before touching
  anything and backs up the CSV to `.bak`. Verified live against contributor.stock.adobe.com.
- **Fixed Vecteezy CSV not applying to files whose names contain spaces or commas** (e.g. Adobe
  Firefly exports like `Firefly_---Piggy bank beside passport, travel fund 207778.jpeg`). Vecteezy
  rewrites the filename on upload — spaces & commas become `_`, and an underscore right before a
  hyphen is dropped (`Firefly_---` → `Firefly---`) — then matches CSV rows against that rewritten
  name. The export now mirrors those rules in the **Filename** column so the rows stop silently
  failing to match. Verified against 20 real uploaded files.
- **GPT-5.4 Mini is now the recommended / default OpenAI model** — faster and cheaper for most
  metadata jobs. You can still switch to GPT-5.4, GPT-5.5, or GPT-5.4 Nano in the dropdown.

### Project

- **Added a Ko-fi Sponsor button.** A `.github/FUNDING.yml` surfaces a **Sponsor** button on the
  repo, and both READMEs now include a "Support this project" section
  ([ko-fi.com/chanuwatsrithong](https://ko-fi.com/chanuwatsrithong)).
- **Polished repository presentation:** added a repo description and topics, unified the live-demo
  URL to <https://metagen-stock-tools.vercel.app>, and synced the version badges and in-app
  `APP_VERSION` to 1.1.0.

## [1.1.0] - 2026-06-13

### MetaGen

- **Deployed online.** MetaGen is now hosted on Vercel and auto-deploys from `main`
  (<https://metagen-stock-tools.vercel.app/>). Renamed `metagen/MetaGen.html` →
  `metagen/index.html` so the bare site URL serves the app with no extra config; removed the
  interim `vercel.json`. Local use is unchanged — double-click `metagen/index.html`.

### Dreamstime Metadata Tool

- **Single self-contained file.** `Dreamstime Metadata Tool.hta` now embeds the PowerShell
  script plus its icon/logo (base64) and unpacks them to `%APPDATA%\DreamstimeMetadataTool`
  at runtime, so the `.hta` works on its own — copy just that one file anywhere, no `.ps1`
  or `assets/` folder needed alongside it. `dreamstime-embed.ps1` and the `.bat` remain as
  the readable source of truth and an optional command-line path.
- **Desktop shortcut button.** Added a **📌 Desktop Shortcut** button that drops a
  nicely-iconned shortcut on your Desktop. (Windows shows generic icons on `.hta`/`.bat`
  files themselves; a shortcut is the supported way to get a custom program icon.)
- **Build script.** `dreamstime-tool/build-standalone-hta.ps1` regenerates the embedded
  payloads from the source files — re-run it after editing `dreamstime-embed.ps1`.

## [1.0.0] - 2026-06-13

First public release. This round restructured both tools into a single GitHub-ready
repository, hardened the Dreamstime tool, refreshed MetaGen's UI and AI model list,
and added bilingual documentation.

### Repository

- **Restructured** the project into `metagen/`, `dreamstime-tool/`, and `docs/`, with a
  git root, `.gitignore`, README, CHANGELOG, and LICENSE.

### MetaGen

- **Platform tiers.** Added a `tier` flag (`verified` / `untested`) to every platform in
  the `PLATS` array. The Platforms tab now shows two groups — **✓ Tested & verified** (8:
  Adobe, Shutterstock, Freepik, Dreamstime, 123RF, Pond5, Vecteezy, General) and
  **🧪 Not yet tested** (6: iStock, Getty, Depositphotos, Alamy, Canva, Motionarray).
  Untested platforms are dimmed and marked, the export-format dropdown uses verified /
  untested `<optgroup>`s, and exporting an untested format raises a warning.
- **Visual fixes.** Fixed the invisible logo (dark→amber gradient now readable on the
  light background) and replaced leftover teal/green theme accents with the current amber
  theme.
- **Version badge.** Added `APP_VERSION = '1.0.0'`, shown under the logo in the header.
- **AI models updated to June 2026:**
  - Claude: `claude-sonnet-4-6` (Recommended), `claude-haiku-4-5` (Fast & Cheap),
    `claude-opus-4-8` (Best Quality).
  - OpenAI: `gpt-5.4` (Recommended), `gpt-5.4-mini` (Fast & Cheap), `gpt-5.5`
    (Best Quality), `gpt-5.4-nano` (Cheapest).
  - Gemini: `gemini-3.5-flash` (Recommended), `gemini-3.1-pro-preview` (Best Quality),
    `gemini-2.5-flash-lite` (Cheapest & Proven).
  - **Note:** access to the newest GPT-5 / Gemini-3 models is account-dependent. If a new
    model is unavailable on your account, `gemini-2.5-flash-lite` is the proven fallback.
  - `MODEL_PRICING` updated to match (USD per 1M tokens, verified Jun 2026).
- **GPT-5 token handling.** GPT-5 requests use `max_completion_tokens` as required by the
  newer OpenAI models.
- **Session save / load.** Added **💾 Save** / **📂 Load** in the results header. Save
  downloads `MetaGen_Session_YYYY-MM-DD_HHmm.json` containing only the text metadata
  (title, description, keywords, category, cost) — no image data, so files stay small.
  Loading restores the rows; restored rows export to CSV normally but have no live image
  (per-row regenerate and thumbnails are disabled for them).

### Dreamstime Metadata Tool

- **Relative-path resolution.** The `.hta` now locates `dreamstime-embed.ps1` and its icon
  relative to its own folder, and the `.bat` finds the script next to itself (with an
  `INSTALL_DIR` override) — no more hard-coded `GPT META gen` paths.
- **Settings persistence.** The GUI remembers the last folder, AI mode, AI model, and the
  sound toggle across runs (`%APPDATA%\DreamstimeMetadataTool\settings.txt`); with no saved
  settings it prompts for a folder instead of guessing a private path.
- **Live progress.** The PS1 accepts `-ProgressFile`; the GUI polls it to show
  "Embedding image X of Y — filename" while running.
- **Dry Run.** Added a **🧪 Dry Run** button (and `-DryRun` switch) that previews which CSV
  rows match which images without writing anything.
- **Neutral messaging.** Removed tool-specific "send a screenshot" wording in favour of
  generic "check the log / open an issue" guidance.
- Renamed the internal `$args` variable to `$exifArgs` to avoid shadowing PowerShell's
  automatic variable (no change to the proven metadata write/verify logic).

### Documentation

- Added bilingual docs: English [`README.md`](./README.md) and
  [`docs/csv-formats.md`](./docs/csv-formats.md); Thai [`README.th.md`](./README.th.md),
  [`docs/metagen-guide.th.md`](./docs/metagen-guide.th.md), and
  [`docs/dreamstime-tool-guide.th.md`](./docs/dreamstime-tool-guide.th.md).
- Added this CHANGELOG and an MIT LICENSE.

[1.0.0]: https://keepachangelog.com/
