# CSV Format Reference

This is the single source of truth for every per-platform CSV that **MetaGen** can export.
All numbers below come directly from the `PLAT_SPECS` object in
[`metagen/MetaGen.html`](../metagen/MetaGen.html). If the code and this table ever
disagree, the code wins — update this file to match.

## Status legend

| Badge | Meaning |
|---|---|
| ✅ Tested 2026-06 | A real upload to this platform succeeded with a MetaGen CSV. |
| ✅ Safe universal | `General` format — a plain 4-column CSV that works as a safe starting point on most sites. Safe by design, no platform test needed. |
| 🧪 Untested | The format is implemented from the platform's published spec but has **not** been confirmed with a real upload yet. Check the CSV by hand before you trust it. |

## How to read the columns

- **CSV headers** — the exact header row written to the file (the first line).
- **Separator** — the character between columns. Most use a comma; Freepik uses a semicolon.
- **BOM** — whether a UTF-8 Byte Order Mark is written at the start of the file. A BOM helps Excel show Thai/accented characters correctly. Platforms that reject a BOM are marked **No**.
- **Title max** — maximum characters MetaGen allows in the title/caption column (`titleMax`). A recommended softer limit (`titleRec`) is shown in parentheses when one exists.
- **Description** — the description column limit (`descMax`), or **None** when that platform's CSV has no description column.
- **Keywords (min–max)** — the keyword count range (`kwMin`–`kwMax`).
- **Keyword sep** — the character between keywords inside the keyword cell (`kwSep`): a comma for almost everyone, a **space** for Alamy.

## Platform reference table

### ✅ Verified — tested with a real upload (2026-06)

| Platform | CSV headers | Separator | BOM | Title max | Description | Keywords (min–max) | Keyword sep | Status |
|---|---|---|---|---|---|---|---|---|
| **Adobe** (Adobe Stock) | `Filename,Title,Keywords,Category,Releases` | Comma | Yes | 200 (rec 70) | None | 5–50 | Comma | ✅ Tested 2026-06 |
| **Shutterstock** | `Filename,Description,Keywords,Categories,Editorial` | Comma | Yes | 200 (rec 120) | None | 7–50 | Comma | ✅ Tested 2026-06 |
| **Freepik** (Freepik / Magnific) | `File name;Title;Keywords;Prompt;Model` | Semicolon | No | 100 | None | 5–50 | Comma | ✅ Tested 2026-06 |
| **Dreamstime** | `Filename,Image Name,Description,Category 1,Category 2,Category 3,keywords,Free,W-EL,P-EL,SR-EL,SR-Price,Editorial,MR doc Ids,Pr Docs` | Comma | Yes | 200 | 1000 (min 50) | 5–50 | Comma | ✅ Tested 2026-06 |
| **123RF** | `"oldfilename","123rf_filename","description","keywords","country"` | Comma | No | 255 | 500 | 1–50 | Comma | ✅ Tested 2026-06 |
| **Pond5** | `originalfilename,title,description,keywords,copyright,price,editorial` | Comma | No | 80 | 500 | 10–50 | Comma | ✅ Tested 2026-06 |
| **Vecteezy** | `Filename,Title,Description,Keywords,License` | Comma | No | 100 | 500 | 5–50 | Comma | ✅ Tested 2026-06 |
| **General** (Universal) | `Filename,Title,Description,Keywords` | Comma | Yes | 200 | 1000 | 1–50 | Comma | ✅ Safe universal |

### 🧪 Untested — implemented but not yet confirmed with a real upload

| Platform | CSV headers | Separator | BOM | Title max | Description | Keywords (min–max) | Keyword sep | Status |
|---|---|---|---|---|---|---|---|---|
| **iStock** (iStock / ESP) | `File Name,Title,Description,Keywords` | Comma | Yes | 200 | 2000 | 5–50 | Comma | 🧪 Untested |
| **Getty** (Getty Images) | `File Name,Caption,Description,Keywords` | Comma | Yes | 500 (rec 200) | 2000 | 5–50 | Comma | 🧪 Untested |
| **Depositphotos** | `file,title,description,keywords` | Comma | Yes | 250 | 500 | 1–70 | Comma | 🧪 Untested |
| **Alamy** | `Filename,Caption,Tags` | Comma | Yes | 500 (rec 200) | None | 1–100 | **Space** | 🧪 Untested |
| **Canva** (Canva Creator) | `filename,title,description,tags` | Comma | Yes | 150 | 500 | 1–30 | Comma | 🧪 Untested |
| **Motionarray** (Motion Array) | `filename,title,description,tags` | Comma | Yes | 100 | 500 | 1–50 | Comma | 🧪 Untested |

> **Note on keyword minimums.** The `kwMin` values above are the spec floor. At
> generate time MetaGen automatically aims a little higher — about 75% of each
> platform's `kwMax` (e.g. ~38 of 50) — so your keyword cells stay well-filled.

## How to verify and promote a platform

When you have actually uploaded a MetaGen CSV to one of the 🧪 untested platforms and
the upload was accepted, you can promote it from *untested* to *verified* so it moves
into the green group in MetaGen's UI. It is a one-line change:

1. **Do a real test first.** Generate metadata in MetaGen, export that platform's CSV,
   upload it on the actual platform, and confirm it imports cleanly (title, description,
   keywords, and category all land correctly).
2. **Open** [`metagen/MetaGen.html`](../metagen/MetaGen.html) in a text editor.
3. **Find the `PLATS` array** (search for `const PLATS = [`). Each platform is one line, e.g.:
   ```js
   {id:'Alamy', nm:'Alamy', ic:'Al', bg:'#1b4d3e', tier:'untested'},
   ```
4. **Change `tier:'untested'` to `tier:'verified'`** for that platform:
   ```js
   {id:'Alamy', nm:'Alamy', ic:'Al', bg:'#1b4d3e', tier:'verified'},
   ```
5. **Save and reload** MetaGen in your browser. The platform now appears under the
   "✓ Tested & verified" group with no 🧪 marker, and the untested export warning no
   longer fires for it.
6. **Update this file** — move that platform's row up into the verified table and change
   its status to `✅ Tested 2026-06` (use the month/year you tested it).

> You do **not** need to touch the `PLAT_SPECS` numbers when promoting — those are the
> format limits and stay the same. The `tier` flag only controls how the platform is
> grouped and warned about in the UI.
