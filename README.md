# MetaGen Stock Tools

![version](https://img.shields.io/badge/version-1.0.0-c8891a)
![license](https://img.shields.io/badge/license-MIT-blue)
![platform](https://img.shields.io/badge/platform-Windows-0078d6)

Two linked Windows tools for stock-photo contributors.

- **MetaGen** — a single-file browser app. Upload images, let AI vision (Claude / OpenAI / Gemini) write the title, description, keywords, and category, then export a ready-to-upload CSV for each stock platform.
- **Dreamstime Metadata Tool** — a desktop helper that reads MetaGen's Dreamstime CSV, copies your images to a new folder, and embeds IPTC/XMP/EXIF metadata with ExifTool so they're ready to upload to Dreamstime. **Your original files are never modified.**

**How they connect:** MetaGen exports `MetaGen_Dreamstime_YYYY-MM-DD.csv`. You drop that
CSV next to your images and run the Dreamstime tool, which embeds the metadata into copies
of those images. MetaGen handles the *thinking* (writing metadata); the Dreamstime tool
handles the *embedding* (baking it into files).

🇹🇭 **ภาษาไทย:** อ่าน [README.th.md](./README.th.md) สำหรับคู่มือฉบับเต็มภาษาไทย

---

## Platform status

MetaGen exports CSV for 14 platforms, grouped by whether a real upload has been confirmed.

| Status | Platforms |
|---|---|
| ✅ **Verified** (tested 2026-06) | Adobe, Shutterstock, Freepik, Dreamstime, 123RF, Pond5, Vecteezy, General |
| 🧪 **Untested** (spec-built, not yet upload-confirmed) | iStock, Getty, Depositphotos, Alamy, Canva, Motionarray |

`General` is a safe universal 4-column format that works as a starting point on most sites.
See [`docs/csv-formats.md`](./docs/csv-formats.md) for exact headers, separators, BOM, and
character limits per platform, plus how to promote a platform from untested to verified.

---

## Quick start

### MetaGen

1. Double-click [`metagen/MetaGen.html`](./metagen/MetaGen.html) — it opens in your browser. Nothing to install.
2. Pick an AI provider (Claude / OpenAI / Gemini) and paste your API key, then click **Test →**.
3. Adjust the title / description / keyword sliders, pick your target platforms, and drop in your images.
4. Click **✦ Generate**, review/edit the rows, then **↓ CSV** (one platform) or **↓ All** (every active platform).

Full guide: [`docs/metagen-guide.th.md`](./docs/metagen-guide.th.md) (Thai).

### Dreamstime Metadata Tool

1. In MetaGen, export the **Dreamstime** CSV and place it in the same folder as your JPG images.
2. Double-click **`dreamstime-tool/Dreamstime Metadata Tool.hta`** for the GUI (or `Dreamstime Embed - Double Click.bat` for no-GUI).
3. Choose the folder, pick AI / Not-AI mode, optionally **🧪 Dry Run**, then **Embed Metadata**.
4. Upload the images from the new **"Dreamstime Ready"** folder it creates.

Full guide: [`docs/dreamstime-tool-guide.th.md`](./docs/dreamstime-tool-guide.th.md) (Thai).

---

## Security

- Your API key lives **only in your browser** (localStorage). Requests go **directly from your browser to the AI provider** you chose — never through any middle server.
- Run everything **locally**. Do **not** commit API keys, and do not share files that contain your key.

---

## Repository layout

```
Fable Metagen/
├── README.md                          ← this file (English)
├── README.th.md                       ← Thai (main guide for the user)
├── CHANGELOG.md
├── LICENSE                            ← MIT
├── .gitignore
├── metagen/
│   └── MetaGen.html                   ← the single-file browser app
├── dreamstime-tool/
│   ├── Dreamstime Metadata Tool.hta   ← GUI launcher
│   ├── dreamstime-embed.ps1           ← the embedding engine
│   ├── Dreamstime Embed - Double Click.bat  ← no-GUI launcher
│   └── assets/                        ← app icons
└── docs/
    ├── csv-formats.md                 ← CSV reference for all 14 platforms (EN)
    ├── metagen-guide.th.md            ← MetaGen guide (TH)
    ├── dreamstime-tool-guide.th.md    ← Dreamstime tool guide (TH)
    └── superpowers/specs/             ← design spec
```

---

## Documentation

- [CSV format reference (EN)](./docs/csv-formats.md) — headers, separators, BOM, limits, status for all 14 platforms.
- [MetaGen guide (TH)](./docs/metagen-guide.th.md) — task-oriented walkthrough.
- [Dreamstime tool guide (TH)](./docs/dreamstime-tool-guide.th.md) — full embed workflow and troubleshooting.

---

## Roadmap

Not in this release, planned for later:

- Parallel generation with per-provider rate-limiting.
- Auto-save sessions to IndexedDB (so work survives a crash, not just manual Save/Load).
- Embed tools for platforms beyond Dreamstime.
- Real-upload-test the 6 untested platforms and promote them to verified.
- Modular refactor / build system.

---

## License

MIT © 2026 srithongchanuwat. See [LICENSE](./LICENSE).
