# MetaGen Stock Tools (คู่มือภาษาไทย)

![version](https://img.shields.io/badge/version-1.0.0-c8891a)
![license](https://img.shields.io/badge/license-MIT-blue)
![platform](https://img.shields.io/badge/platform-Windows-0078d6)

ชุดเครื่องมือ 2 ตัวสำหรับคนทำ stock photo บน Windows ทำงานต่อเนื่องกัน:

1. **MetaGen** — เว็บแอปไฟล์เดียว เปิดในเบราว์เซอร์ อัปโหลดรูป → ให้ AI (Claude / OpenAI / Gemini)
   เขียน title / description / keywords / category ให้ → export ออกมาเป็น CSV ตามรูปแบบของแต่ละแพลตฟอร์ม
2. **Dreamstime Metadata Tool** — โปรแกรมบนเครื่อง อ่าน CSV ของ Dreamstime จาก MetaGen,
   คัดลอกรูปไปโฟลเดอร์ใหม่, แล้วฝัง metadata (IPTC / XMP / EXIF) ด้วย ExifTool ให้พร้อมอัปโหลด
   **โดยไม่แตะไฟล์ต้นฉบับ**

> 🇬🇧 ฉบับภาษาอังกฤษ (สั้นกว่า): [README.md](./README.md)

---

## เครื่องมือ 2 ตัวเชื่อมกันอย่างไร

```
รูปภาพ
  │
  ▼
MetaGen (เบราว์เซอร์)  ── AI เขียน metadata ──►  export CSV
  │
  ├─►  CSV ของแพลตฟอร์มทั่วไป  ──►  อัปโหลดขึ้นเว็บนั้นได้เลย
  │
  └─►  MetaGen_Dreamstime_YYYY-MM-DD.csv
            │
            ▼
       วาง CSV ในโฟลเดอร์รูป
            │
            ▼
   Dreamstime Metadata Tool  ── ฝัง metadata ลงไฟล์สำเนา ──►  โฟลเดอร์ "Dreamstime Ready"
            │
            ▼
       อัปโหลดขึ้น Dreamstime
```

- **MetaGen** ทำหน้าที่ "คิด" (เขียน metadata)
- **Dreamstime tool** ทำหน้าที่ "ฝัง" (อบ metadata ลงในไฟล์ภาพ)

---

## สถานะแพลตฟอร์ม

MetaGen export CSV ได้ 14 แพลตฟอร์ม แบ่งเป็น 2 กลุ่มตามว่าอัปโหลดจริงผ่านแล้วหรือยัง:

| สถานะ | แพลตฟอร์ม |
|---|---|
| ✅ **ทดสอบแล้ว** (2026-06) | Adobe, Shutterstock, Freepik, Dreamstime, 123RF, Pond5, Vecteezy, General |
| 🧪 **ยังไม่ทดสอบ** (ทำตามสเปคไว้ แต่ยังไม่ยืนยันด้วยการอัปโหลดจริง) | iStock, Getty, Depositphotos, Alamy, Canva, Motionarray |

`General` เป็นรูปแบบกลาง 4 คอลัมน์ที่ปลอดภัยใช้เป็นจุดเริ่มกับเว็บส่วนใหญ่ได้
รายละเอียดเต็ม (headers, separator, BOM, ขีดจำกัด) ดู [`docs/csv-formats.md`](./docs/csv-formats.md)

---

## เริ่มใช้งานอย่างเร็ว

### MetaGen

1. ดับเบิลคลิก [`metagen/index.html`](./metagen/index.html) — เปิดในเบราว์เซอร์ ไม่ต้องติดตั้งอะไร
2. เลือก provider (Claude / OpenAI / Gemini) วาง API key แล้วกด **Test →**
3. ตั้ง sliders, เลือกแพลตฟอร์มเป้าหมาย, ลากรูปมาวาง
4. กด **✦ Generate** → ตรวจ/แก้ผลลัพธ์ → **↓ CSV** หรือ **↓ All**

คู่มือเต็ม: [`docs/metagen-guide.th.md`](./docs/metagen-guide.th.md)

### Dreamstime Metadata Tool

1. ใน MetaGen export CSV format **Dreamstime** แล้ววางไฟล์ในโฟลเดอร์เดียวกับรูป JPG
2. ดับเบิลคลิก **`dreamstime-tool/Dreamstime Metadata Tool.hta`** (แบบ GUI)
   หรือ `Dreamstime Embed - Double Click.bat` (แบบไม่มี GUI)
3. เลือกโฟลเดอร์, เลือกโหมด AI / ไม่ใช่ AI, (แนะนำ) กด **🧪 Dry Run** ก่อน, แล้วกด **Embed Metadata**
4. อัปโหลดรูปจากโฟลเดอร์ **"Dreamstime Ready"** ใหม่ที่โปรแกรมสร้างให้

คู่มือเต็ม: [`docs/dreamstime-tool-guide.th.md`](./docs/dreamstime-tool-guide.th.md)

---

## 🔒 ความปลอดภัย

- API key เก็บอยู่ **ในเบราว์เซอร์เครื่องคุณเท่านั้น** (localStorage)
- คำขอ generate **ส่งตรงจากเบราว์เซอร์ไปยัง AI provider** ที่เลือก ไม่ผ่านเซิร์ฟเวอร์กลางของใคร
- ใช้งานในเครื่องเท่านั้น **อย่า commit key ขึ้น GitHub** และอย่าแชร์ไฟล์ที่มี key ติดไป

---

## 📦 ย้ายมาจากโฟลเดอร์เก่า "GPT META gen"

repo นี้คือการจัดโครงสร้างใหม่ของเครื่องมือที่เคยอยู่ในโฟลเดอร์ **`GPT META gen`** เดิม
สิ่งที่ต้องรู้:

- โฟลเดอร์เก่า `C:\Users\Darks\Documents\GPT META gen` เก็บไว้เป็น **backup ก่อนปรับโครงสร้าง**
- **shortcut เดิม** (เช่นที่หน้า Desktop) ที่ชี้ไปโฟลเดอร์เก่า ต้อง **ชี้มาที่ไฟล์ใหม่ในโฟลเดอร์นี้แทน**
  - MetaGen → `Fable Metagen\metagen\index.html`
  - Dreamstime tool → `Fable Metagen\dreamstime-tool\Dreamstime Metadata Tool.hta`
- **อย่าเพิ่งลบโฟลเดอร์เก่า** จนกว่าจะทดสอบของใหม่ครบและมั่นใจแล้ว เมื่อพร้อมค่อยลบเองด้วยมือ

---

## โครงสร้างโฟลเดอร์

```
Fable Metagen/
├── README.md                          ← อังกฤษ
├── README.th.md                       ← ไทย (ไฟล์นี้)
├── CHANGELOG.md
├── LICENSE                            ← MIT
├── .gitignore
├── metagen/
│   └── index.html                   ← เว็บแอปไฟล์เดียว
├── dreamstime-tool/
│   ├── Dreamstime Metadata Tool.hta   ← ตัวเปิดแบบ GUI
│   ├── dreamstime-embed.ps1           ← สคริปต์ฝัง metadata
│   ├── Dreamstime Embed - Double Click.bat  ← ตัวเปิดแบบไม่มี GUI
│   └── assets/                        ← ไอคอน
└── docs/
    ├── csv-formats.md                 ← ตารางรูปแบบ CSV ทุกแพลตฟอร์ม (EN)
    ├── metagen-guide.th.md            ← คู่มือ MetaGen (TH)
    ├── dreamstime-tool-guide.th.md    ← คู่มือ Dreamstime tool (TH)
    └── superpowers/specs/             ← เอกสารออกแบบ
```

---

## เอกสารทั้งหมด

- [คู่มือ MetaGen (TH)](./docs/metagen-guide.th.md)
- [คู่มือ Dreamstime tool (TH)](./docs/dreamstime-tool-guide.th.md)
- [ตารางรูปแบบ CSV ทุกแพลตฟอร์ม (EN)](./docs/csv-formats.md)

---

## Roadmap (แผนในอนาคต ไม่อยู่ในรอบนี้)

- generate แบบขนาน (concurrency) + จำกัด rate ต่อ provider
- auto-save session ลง IndexedDB (กันงานหายแม้ไม่กด Save เอง)
- เครื่องมือ embed metadata สำหรับแพลตฟอร์มอื่นนอกจาก Dreamstime
- ทดสอบจริง 6 แพลตฟอร์มที่ยังไม่ทดสอบ แล้วเลื่อนเป็น verified
- รื้อโครงสร้างเป็นโมดูล / build system

---

## License

MIT © 2026 srithongchanuwat ดูไฟล์ [LICENSE](./LICENSE)
