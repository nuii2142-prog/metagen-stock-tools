# MetaGen Stock Tools

[![version](https://img.shields.io/badge/version-1.1.0-c8891a)](./CHANGELOG.md)
[![license](https://img.shields.io/badge/license-MIT-blue)](./LICENSE)
![platform](https://img.shields.io/badge/platform-Windows%20%7C%20Browser-0078d6)
[![Support on Ko-fi](https://img.shields.io/badge/support-Ko--fi-ff5e5b?logo=kofi&logoColor=white)](https://ko-fi.com/chanuwatsrithong)

Two linked Windows tools for stock-photo contributors.

- **MetaGen** — a single-file browser app. Upload images, let AI vision (Claude / OpenAI / Gemini) write the title, description, keywords, and category, then export a ready-to-upload CSV for each stock platform.
- **Dreamstime Metadata Tool** — a desktop helper that reads MetaGen's Dreamstime CSV, copies your images to a new folder, and embeds IPTC/XMP/EXIF metadata with ExifTool so they're ready to upload to Dreamstime. **Your original files are never modified.**

**How they connect:** MetaGen exports `MetaGen_Dreamstime_YYYY-MM-DD.csv`. You drop that
CSV next to your images and run the Dreamstime tool, which embeds the metadata into copies
of those images. MetaGen handles the *thinking* (writing metadata); the Dreamstime tool
handles the *embedding* (baking it into files).

🌐 **Try MetaGen online (no install):** **<https://metagen-stock-tools.vercel.app/>** — runs entirely in your browser; you bring your own AI API key (nothing is sent to any middle server). The Dreamstime tool is Windows-only and runs locally.

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

1. Double-click [`metagen/index.html`](./metagen/index.html) — it opens in your browser. Nothing to install.
2. Pick an AI provider (Claude / OpenAI / Gemini) and paste your API key, then click **Test →**.
3. Adjust the title / description / keyword sliders, pick your target platforms, and drop in your images.
4. Click **✦ Generate**, review/edit the rows, then **↓ CSV** (one platform) or **↓ All** (every active platform).

Full guide: [`docs/metagen-guide.th.md`](./docs/metagen-guide.th.md) (Thai).

**Adobe CSV rows not applying to files with `[brackets]`?** Adobe Stock's bulk-CSV matcher
silently skips filenames containing `[ ]` (common in Adobe Firefly exports like
`Firefly_---[Wildlife portrait] ... .jpeg`) — Adobe keeps the uploaded filename as-is, so this
can't be fixed in the CSV alone. Drag the image folder onto
**`metagen/Clean Adobe filenames.bat`**: it previews the rename, then on confirm strips the
`[...]` segment from both the image files and the CSV's Filename column so they stay matched.

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
│   ├── index.html                   ← the single-file browser app
│   ├── Clean Adobe filenames.bat    ← drag-and-drop fix for Adobe's [bracket] CSV bug
│   └── clean_adobe_filenames.py     ← the rename/patch engine behind the .bat
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

## Support this project

MetaGen and the Dreamstime tool are **free and open-source**, built for the stock-contributor
community. There's no paywall, no account, and nothing to install for the web app. If these
tools save you time on your metadata workflow, you can support continued development:

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/chanuwatsrithong)

> ☕ Every coffee helps keep these tools free, maintained, and ad-free. Thank you!

---

## License

MIT © 2026 srithongchanuwat. See [LICENSE](./LICENSE).
