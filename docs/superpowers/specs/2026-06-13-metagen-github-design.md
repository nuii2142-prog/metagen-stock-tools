# Design: MetaGen + Dreamstime Tool — Fix, Polish, GitHub-Ready

**วันที่:** 2026-06-13
**สถานะ:** อนุมัติโดยผู้ใช้แล้ว (แนวทาง B — Fix + Professional Polish)
**ขอบเขต:** ปรับปรุงเครื่องมือ 2 ตัวในโฟลเดอร์นี้ให้พร้อมใช้งานระยะยาว และนำขึ้น GitHub แบบ private repo เดียว

---

## 1. ภาพรวมระบบ

เครื่องมือ 2 ตัวทำงานต่อเนื่องกัน:

1. **MetaGen** (`MetaGen.html`) — เว็บแอปไฟล์เดียว เปิดในเบราว์เซอร์ อัปโหลดรูป → เรียก AI (Claude / OpenAI / Gemini) สร้าง title / description / keywords / category → export CSV ตาม format ของแต่ละ stock platform
2. **Dreamstime Metadata Tool** (`.hta` + `.ps1` + `.bat`) — รับ CSV ของ Dreamstime จาก MetaGen, คัดลอกรูปไปโฟลเดอร์ใหม่, ฝัง IPTC/XMP/EXIF metadata ด้วย ExifTool, สร้าง verification report (ไม่แตะไฟล์ต้นฉบับ)

**สัญญาเชื่อมระหว่างกัน (CSV contract):** ไฟล์ `MetaGen_Dreamstime_YYYY-MM-DD.csv` headers:
`Filename,Image Name,Description,Category 1,Category 2,Category 3,keywords,Free,W-EL,P-EL,SR-EL,SR-Price,Editorial,MR doc Ids,Pr Docs`

## 2. การตัดสินใจที่ยืนยันแล้ว

| เรื่อง | ตัดสินใจ |
|---|---|
| โครงสร้าง repo | repo เดียว รวม 2 เครื่องมือ |
| Visibility | Private (เปลี่ยน public ทีหลังได้) |
| ชื่อ repo เสนอ | `metagen-stock-tools` |
| แยกแพลตฟอร์ม | 2 กลุ่มชัดเจนใน UI: ทดสอบแล้ว / ยังไม่ทดสอบ |
| ภาษาเอกสาร | อังกฤษ (README.md) + ไทย (README.th.md + คู่มือใน docs/) |
| สถาปัตยกรรม | คงเดิม: single-file HTML + HTA/PS1 (ไม่มี build system) |

## 3. โครงสร้าง repo เป้าหมาย

```
Fable Metagen/                      ← git root (โฟลเดอร์ปัจจุบัน)
├── README.md                       ← อังกฤษ
├── README.th.md                    ← ไทย (คู่มือหลัก)
├── CHANGELOG.md                    ← เริ่ม v1.0.0
├── LICENSE                         ← MIT (copyright = GitHub username ของผู้ใช้)
├── .gitignore
├── metagen/
│   └── MetaGen.html
├── dreamstime-tool/
│   ├── Dreamstime Metadata Tool.hta
│   ├── dreamstime-embed.ps1
│   ├── Dreamstime Embed - Double Click.bat
│   └── assets/                     ← ไอคอน 3 ไฟล์
└── docs/
    ├── csv-formats.md
    ├── metagen-guide.th.md
    ├── dreamstime-tool-guide.th.md
    └── superpowers/specs/          ← เอกสารออกแบบ (ไฟล์นี้)
```

`.gitignore`:
```
graphify-out/
dreamstime-tool/tools/
*.log
Thumbs.db
desktop.ini
MetaGen_*.csv
Dreamstime Ready */
```

ลำดับ commit: (1) snapshot ไฟล์เดิม + spec นี้ → (2) ย้ายโครงสร้างโฟลเดอร์ → (3..n) การแก้ไขทีละเรื่อง → diff อ่านง่ายทุกขั้น

## 4. MetaGen — แยกกล่องแพลตฟอร์ม

**Data model:** เพิ่ม `tier` ใน `PLATS` แต่ละตัว ค่า `'verified'` หรือ `'untested'` (จุดแก้จุดเดียวเมื่อทดสอบผ่านเพิ่ม)

- **verified (8):** Adobe, Shutterstock, Freepik, Dreamstime, 123RF, Pond5, Vecteezy, General
- **untested (6):** iStock, Getty, Depositphotos, Alamy, Canva, Motionarray

**UI (แท็บ Platforms):**
- `initPlats()` เรนเดอร์ 2 ส่วน: หัวข้อ "✓ ทดสอบแล้ว" + grid, หัวข้อ "🧪 ยังไม่ทดสอบ" + grid
- ตัว untested ใช้ style จางลง (opacity ต่ำกว่า) + เมื่อเปิดใช้มีจุด/ป้ายเตือนเล็ก
- กล่อง Platform Specs (`renderPlatInfo`) เพิ่มบรรทัดเตือนเมื่อ format ที่เลือกเป็น untested
- Dropdown `expFmt` (`renderExpFmt`) ใช้ `<optgroup label="✓ Verified">` / `<optgroup label="🧪 Untested">`

**Export safeguard:**
- `validateExport()` เพิ่ม warning เมื่อ fmtId เป็น untested: "format ยังไม่ผ่านการทดสอบจริงกับแพลตฟอร์ม — ตรวจ CSV ก่อนอัปโหลด"
- `exportCSV()` / `exportAllCSV()` แจ้ง notif เตือนเมื่อมี untested อยู่ในชุดที่ export

**Migration:** id แพลตฟอร์มไม่เปลี่ยน → `activePlats` ที่บันทึกใน localStorage ใช้ต่อได้ทันที

## 5. MetaGen — แก้บั๊กภาพ + อัปเดตโมเดล + เวอร์ชัน

1. **โลโก้มองไม่เห็น:** `.logo-tx` ใช้ `linear-gradient(90deg,#fff 30%,var(--ac))` บนพื้นขาว → เปลี่ยนเป็น gradient สีเข้ม (เช่น `var(--tx)` → `var(--ac)`) อ่านชัดบนพื้นสว่าง
2. **สีเขียวธีมเก่าตกค้าง:** `rgba(0,229,160,…)` 3 จุด (slider thumb shadow, `.drop-ico` background, จุดอื่นถ้าพบ) → เปลี่ยนเป็นโทน accent ส้มปัจจุบัน
3. **โมเดล Claude (PROVIDERS.claude.models):** อัปเดตเป็น
   - `claude-sonnet-4-6` — Sonnet 4.6 · Recommended
   - `claude-haiku-4-5-20251001` — Haiku 4.5 · Fast & Cheap
   - `claude-opus-4-8` — Opus 4.8 · Best Quality
   ราคาใน `MODEL_PRICING`: **ห้ามใส่จากความจำ** — ตรวจจาก claude-api reference skill ระหว่าง implement
4. **โมเดล OpenAI / Gemini:** ตรวจรุ่น + ราคาปัจจุบันจากเว็บ (web search) แล้วอัปเดตทั้ง `PROVIDERS` และ `MODEL_PRICING`; ถ้าแหล่งข้อมูลไม่ชัดเจน คงรายการเดิมไว้และบันทึกใน CHANGELOG ว่ารายการใดยังไม่ได้ตรวจ
5. **เวอร์ชัน:** เพิ่ม `const APP_VERSION='1.0.0'` แสดงใน header (เช่น ใต้โลโก้) + อัปเดตทุกครั้งที่แก้ตาม CHANGELOG
6. Settings เดิมไม่พัง: `loadSettings()` มี guard เลือกเฉพาะ option ที่ยังมีอยู่แล้ว (ตรวจซ้ำตอนทดสอบ)

## 6. MetaGen — Save/Load Session

**ปุ่ม:** แถบ Results header — `💾 Save` / `📂 Load` (disabled ระหว่าง `isGen`)

**Save:** ดาวน์โหลด `MetaGen_Session_YYYY-MM-DD_HHmm.json`
```json
{ "app":"MetaGen", "version":"1.0.0", "savedAt":"ISO",
  "results":[{ "fileName":"a.jpg", "title":"...", "description":"...",
               "keywords":["..."], "category":11,
               "_cost":0.01, "_inputTokens":1, "_outputTokens":1 }] }
```
ไม่เก็บรูป/preview → ไฟล์เล็ก ไม่ติดข้อจำกัด localStorage

**Load:** input file .json → ตรวจ `app==="MetaGen"` + มี array `results` → สร้างแถว `{file:{name:fileName}, id:randomUUID(), restored:true, ...meta}` ผ่าน `normalizeMetadata` → `refreshResultsState({rebuild:true})` + `recalcSessionTotals()`
- แถว `restored` ไม่มีไฟล์รูปจริง: ปุ่ม 🔄 regen ต่อแถว disabled, thumbnail ไม่แสดง, export CSV ทำงานปกติ (ใช้แค่ `file.name`)
- ถ้ามี results ค้างอยู่ → `confirm()` ก่อนแทนที่ (replace ทั้งชุด ไม่ merge)
- JSON ผิดรูปแบบ → notif error, ไม่แตะ state เดิม

## 7. Dreamstime tool — path อัตโนมัติ + จำค่า

**HTA (`Dreamstime Metadata Tool.hta`):**
- คำนวณโฟลเดอร์ตัวเองจาก `location.pathname` (decodeURIComponent → แปลง `/` เป็น `\` → ตัดชื่อไฟล์ออก)
- `SCRIPT_PATH = <hta dir>\dreamstime-embed.ps1` — เลิกฮาร์ดโค้ด `GPT META gen`
- ไอคอน `hta:application icon` ใช้ path สัมพัทธ์ `assets\dreamstime-tool-icon.ico` (ทดสอบจริง; ถ้า mshta ไม่รองรับ ให้ตัด attribute ออก — โลโก้ `<img>` ใช้ relative อยู่แล้ว)
- **Settings คงอยู่ข้ามการเปิด:** ไฟล์ `%APPDATA%\DreamstimeMetadataTool\settings.txt` รูปแบบ `key=value` ต่อบรรทัด (Unicode): `lastFolder`, `aiMode`, `aiModel`, `sound` — โหลดตอน `init()` (แทน `DEFAULT_FOLDER` ฮาร์ดโค้ด), บันทึกเมื่อกด Run และเมื่อค่าเปลี่ยน
- ถ้าไม่มี settings → ช่องโฟลเดอร์ว่าง พร้อมข้อความแนะนำให้กด Choose Folder (ไม่เดา path ส่วนตัว)

**BAT (`Dreamstime Embed - Double Click.bat`):**
- ลำดับหา script: (1) `%~dp0dreamstime-embed.ps1` (วางคู่กัน) → (2) ตัวแปร `INSTALL_DIR` ที่หัวไฟล์ (คอมเมนต์บอกวิธีแก้ชัดเจน, ค่าเริ่มต้น `%USERPROFILE%\Documents\Fable Metagen\dreamstime-tool`) → (3) error message ชัดเจน
- ตัวแปร `AI_MODE` / `AI_MODEL` ยกขึ้นหัวไฟล์เป็นจุดแก้เดียว
- ลบข้อความ "send Codex a screenshot" → ข้อความ generic ("ตรวจ log ด้านบน / เปิด issue ใน repo")

## 8. Dreamstime tool — Progress สด + Dry Run

**PS1:**
- เพิ่มพารามิเตอร์ optional `-ProgressFile <path>`: เมื่อกำหนด เขียนสถานะต่อไฟล์รูปด้วย `Set-Content` (atomic, เลี่ยงปัญหา stdout buffering): `i|total|filename|status`
- stdout เดิมคงไว้ทั้งหมด (CLI ใช้เหมือนเดิม) + เพิ่มบรรทัดสรุปต่อไฟล์ใน verbose ของ report
- เปลี่ยนชื่อตัวแปร `$args` → `$exifArgs` ใน `Invoke-ExifToolWrite` / `Invoke-ExifToolVerify` (เลี่ยง automatic variable; **ห้ามแก้ logic การเขียน/ตรวจ metadata** — ผ่านการทดสอบจริงแล้ว)

**HTA:**
- `runEmbed()` รันผ่าน `cmd /c "powershell … -File script … -ProgressFile <tmp> > <tmp log> 2>&1"` ด้วย `shell.Exec` → poll ทุก 700ms: อ่าน progress file → อัปเดตสถานะ "กำลังทำรูปที่ X จาก Y — filename" + อ่าน log file → แสดง tail ในกล่อง log สด
- จบงาน: แสดง log เต็ม + exit code เดิม + เปิดโฟลเดอร์ output (พฤติกรรมเดิม)
- เพิ่มปุ่ม **🧪 Dry Run**: รันด้วย `-DryRun` แสดงผลการจับคู่ CSV↔รูป (กี่ไฟล์เจอ/ขาด/ซ้ำ) โดยไม่เขียนอะไรจริง
- log ชั่วคราวอยู่ `%TEMP%` ตั้งชื่อ timestamped; แสดง path ไว้ใน log box บรรทัดแรกเพื่อตรวจย้อนหลัง

## 9. เอกสาร

| ไฟล์ | เนื้อหา |
|---|---|
| `README.md` (EN) | ภาพรวม 2 เครื่องมือ, สถานะแพลตฟอร์ม (ตาราง verified/untested), quick start, security note (API key อยู่ในเบราว์เซอร์ เรียก provider ตรง ไม่ผ่าน server กลาง; แนะนำใช้ในเครื่องเท่านั้น), ลิงก์ไป docs |
| `README.th.md` (TH) | ฉบับเต็มภาษาไทย: ติดตั้ง/เปิดใช้, workflow ครบวงจร MetaGen → CSV → Dreamstime tool → upload, FAQ, หมายเหตุย้ายจากโฟลเดอร์เก่า (shortcut เดิมชี้ "GPT META gen" ต้องอัปเดต; เก็บโฟลเดอร์เก่าเป็น backup จนตรวจครบ) |
| `docs/csv-formats.md` | ตารางสเปคทุกแพลตฟอร์ม: headers, separator, BOM, ขีดจำกัด title/desc/keywords, สถานะทดสอบ + วันที่ทดสอบ (7 แพลตฟอร์มทดสอบจริง = 2026-06; General = format กลาง ปลอดภัยโดยการออกแบบ ไม่ต้องทดสอบกับแพลตฟอร์ม; อีก 6 = untested), แหล่งอ้างอิง spec ในโค้ด (`PLAT_SPECS`) |
| `docs/metagen-guide.th.md` | คู่มือ MetaGen ละเอียด: ทุก setting, keyword rank, cost tracking, save/load session, การเพิ่ม/ทดสอบแพลตฟอร์มใหม่ (ขั้นตอนย้าย tier) |
| `docs/dreamstime-tool-guide.th.md` | คู่มือ HTA + ps1 + bat: ทุกปุ่ม, dry run, อ่าน report CSV, troubleshooting (ExifTool download, execution policy) |
| `CHANGELOG.md` | v1.0.0 — บันทึกการแก้ทั้งหมดรอบนี้ |
| `LICENSE` | MIT — copyright holder = GitHub username (ดึงจาก `gh api user` ตอน implement) |

## 10. Git / GitHub

1. `git init` (branch `main`) ในโฟลเดอร์นี้ + `.gitignore`
2. Commit 1: snapshot ไฟล์เดิมทั้งหมด + spec นี้
3. Commit ตามลำดับงาน (โครงสร้าง → MetaGen tier → MetaGen bugs/models → session → HTA/BAT/PS1 → เอกสาร)
4. ตรวจ `gh auth status` → `gh repo create metagen-stock-tools --private --source . --push`
5. โฟลเดอร์เก่า `GPT META gen` ไม่แตะต้อง — ผู้ใช้ลบเองหลังตรวจของใหม่ครบ

## 11. การทดสอบ (verify ก่อนปิดงาน)

- **PS1:** สร้าง fixture (รูป JPG เล็ก + CSV ตัวอย่าง) → รัน `-DryRun` → รันจริง → อ่าน metadata กลับด้วย `exiftool -j` ตรวจ Title/Description/Keywords/DigitalSourceType → ตรวจ report CSV + กรณี missing/ambiguous/invalid + ตรวจว่า progress file ถูกเขียน
- **BAT:** รันในโฟลเดอร์ fixture ตรวจหา script เจอทั้งกรณีวางคู่และกรณีใช้ INSTALL_DIR
- **MetaGen:** เปิดในเบราว์เซอร์ → ตรวจโลโก้/สี, สองกลุ่มแพลตฟอร์ม, optgroup, inject ผลลัพธ์จำลองผ่าน console → export CSV ทุก format ที่ tested, save session → reload → load session → export ซ้ำได้, ตรวจ warning เมื่อ export untested
- **HTA:** เปิดจริงบนเครื่อง ตรวจ path อัตโนมัติ + จำค่า + log สด + dry run (ผู้ใช้ร่วมทดสอบรอบสุดท้าย)
- รายงานผลทดสอบทั้งหมดให้ผู้ใช้พร้อมหลักฐาน (output/screenshot) ก่อนสรุปงาน

## 12. นอกขอบเขตรอบนี้ (roadmap ใน README)

- การ generate แบบขนาน (concurrency) + rate-limit ต่อ provider
- Auto-save session ลง IndexedDB
- เครื่องมือ embed metadata สำหรับแพลตฟอร์มอื่นนอกจาก Dreamstime
- ทดสอบจริง 6 แพลตฟอร์ม untested แล้วย้าย tier
- รื้อโครงสร้างเป็นโมดูล/build system (แนวทาง C)
