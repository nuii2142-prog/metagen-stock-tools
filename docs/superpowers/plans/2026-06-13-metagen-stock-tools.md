# MetaGen Stock Tools — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make MetaGen (single-file web app) and the Dreamstime metadata tool (HTA + PS1 + BAT) professional, GitHub-ready, and maintainable — with tested/untested platforms clearly separated, bugs fixed, session save/load added, current AI models, and the Dreamstime tool self-locating with live progress.

**Architecture:** No build system. MetaGen stays one `MetaGen.html`. The Dreamstime tool stays HTA (UI) → PowerShell (`dreamstime-embed.ps1`, does the work via ExifTool) → BAT (double-click runner). Files reorganized into `metagen/`, `dreamstime-tool/`, `docs/`, committed to a private GitHub repo. Edits are surgical — the working metadata-embedding logic is preserved exactly; only path resolution, progress, and UX change.

**Tech Stack:** HTML/CSS/vanilla JS (MetaGen), HTA + JScript (Dreamstime UI), Windows PowerShell 5.1 + ExifTool (embedding), batch script, Git + GitHub CLI.

**Spec:** `docs/superpowers/specs/2026-06-13-metagen-github-design.md`

---

## Conventions for every task

- **Verification, not unit tests.** This stack has no test runner. Each task's "test" is: run the app/script and observe the documented result. Treat a mismatch as a failure — fix before moving on. The one exception is the PS1, which gets a real fixture-based smoke test (Task 5.4).
- **Commit after each task** that leaves the tree working. Branch is `main`. Commit message style: `area: short imperative`. End every commit body with the Co-Authored-By line:
  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  ```
- **Never touch** the ExifTool argument construction in `Invoke-ExifToolWrite` / `Invoke-ExifToolVerify` except the documented variable rename. That logic is field-tested and correct.
- **Paths below are relative to the git root** `C:\Users\Darks\Documents\Fable Metagen`.

---

## File Structure (target)

```
Fable Metagen/                       ← git root
├── README.md                        ← EN (new)
├── README.th.md                     ← TH main guide (new)
├── CHANGELOG.md                     ← new, v1.0.0
├── LICENSE                          ← MIT (new)
├── .gitignore                       ← exists
├── metagen/
│   └── MetaGen.html                 ← moved + edited
├── dreamstime-tool/
│   ├── Dreamstime Metadata Tool.hta ← moved + edited
│   ├── dreamstime-embed.ps1         ← moved + edited
│   ├── Dreamstime Embed - Double Click.bat ← moved + edited
│   └── assets/                      ← moved (3 icon files)
└── docs/
    ├── csv-formats.md               ← new
    ├── metagen-guide.th.md          ← new
    ├── dreamstime-tool-guide.th.md  ← new
    └── superpowers/{specs,plans}/   ← exists
```

Responsibility per file: `MetaGen.html` = generate metadata + export CSV; `dreamstime-embed.ps1` = embed metadata into copied images; `.hta` = friendly GUI wrapper around the PS1; `.bat` = no-GUI double-click runner; `docs/*` = how to use and extend.

---

## Phase 0 — Repository restructure

### Task 0.1: Move files into the new folder layout

**Files:**
- Move: `MetaGen.html` → `metagen/MetaGen.html`
- Move: `Dreamstime Metadata Tool.hta`, `dreamstime-embed.ps1`, `Dreamstime Embed - Double Click.bat` → `dreamstime-tool/`
- Move: `assets/` → `dreamstime-tool/assets/`

- [ ] **Step 1: Create folders and move with git**

Run (PowerShell, from git root):
```powershell
New-Item -ItemType Directory -Force metagen, dreamstime-tool | Out-Null
git mv "MetaGen.html" "metagen/MetaGen.html"
git mv "Dreamstime Metadata Tool.hta" "dreamstime-tool/Dreamstime Metadata Tool.hta"
git mv "dreamstime-embed.ps1" "dreamstime-tool/dreamstime-embed.ps1"
git mv "Dreamstime Embed - Double Click.bat" "dreamstime-tool/Dreamstime Embed - Double Click.bat"
git mv "assets" "dreamstime-tool/assets"
```

- [ ] **Step 2: Verify the tree**

Run: `git status --short`
Expected: five `R` (rename) entries, nothing untracked except already-ignored `graphify-out/`.

- [ ] **Step 3: Verify MetaGen still references its icon correctly**

`metagen/MetaGen.html` references no external asset (logo is a CSS letter "M"). The Dreamstime `.hta` uses `assets/dreamstime-tool-icon.png` relative — now correct because assets moved alongside it. No path edit needed here; the `.hta` hardcoded paths are fixed in Phase 6.

- [ ] **Step 4: Commit**
```powershell
git add -A
git commit -m @'
chore: restructure into metagen/, dreamstime-tool/, docs/

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
'@
```

---

## Phase 1 — MetaGen: separate tested vs untested platforms

All edits in `metagen/MetaGen.html`.

### Task 1.1: Add a `tier` field to the platform data model

**Files:** Modify `metagen/MetaGen.html` — the `PLATS` array (search for `const PLATS = [`).

- [ ] **Step 1: Add `tier` to every entry**

Replace the whole `PLATS` array with (verified tier per the user: Adobe, Shutterstock, Freepik, Dreamstime, 123RF, Pond5, Vecteezy tested; General is a safe-by-design universal format → treat as verified; the rest untested):
```javascript
const PLATS = [
  {id:'Adobe',        nm:'Adobe',      ic:'St', bg:'#e8231a', tier:'verified'},
  {id:'Shutterstock', nm:'Shutterstock',ic:'SS',bg:'#ee2222', tier:'verified'},
  {id:'Freepik',      nm:'Freepik',   ic:'FP', bg:'#1273eb', tier:'verified'},
  {id:'Dreamstime',   nm:'Dreams...',  ic:'Dt', bg:'#007dc3', tier:'verified'},
  {id:'123RF',        nm:'123RF',     ic:'3F', bg:'#f5a623', tier:'verified'},
  {id:'Pond5',        nm:'Pond5',     ic:'P5', bg:'#00c4b4', tier:'verified'},
  {id:'Vecteezy',     nm:'Vecteezy', ic:'Vz', bg:'#ff6b35', tier:'verified'},
  {id:'General',      nm:'General',   ic:'✦',  bg:'#00c47a', tier:'verified'},
  {id:'iStock',       nm:'iStock',    ic:'iS', bg:'#1e1e1e', tier:'untested'},
  {id:'Getty',        nm:'Getty',     ic:'G',  bg:'#1b1b1b', tier:'untested'},
  {id:'Depositphotos',nm:'Deposit...',ic:'DP',bg:'#222',     tier:'untested'},
  {id:'Alamy',        nm:'Alamy',     ic:'Al', bg:'#1b4d3e', tier:'untested'},
  {id:'Canva',        nm:'Canva',     ic:'Ca', bg:'#00c4cc', tier:'untested'},
  {id:'Motionarray',  nm:'Motion...',ic:'Mo', bg:'#6c4fff', tier:'untested'},
];
```

- [ ] **Step 2: Add a helper to read a platform's tier by id**

Immediately after the `PLATS` array, add:
```javascript
const PLAT_TIER = Object.fromEntries(PLATS.map(p => [p.id, p.tier]));
function isUntested(id){ return PLAT_TIER[id] === 'untested'; }
```

- [ ] **Step 3: Verify no syntax error**

Open `metagen/MetaGen.html` in a browser, open DevTools console. Expected: no errors on load; the platform grid still renders 14 tiles.

- [ ] **Step 4: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: tag platforms with verified/untested tier"
```

### Task 1.2: Render the platform grid in two labelled groups

**Files:** Modify `metagen/MetaGen.html` — `initPlats()` and the grid CSS.

- [ ] **Step 1: Add CSS for group headers and untested dimming**

In the `<style>` block, after the `.plat-grid` rules (search `.plat-grid{`), add:
```css
.plat-group-hd{font-family:'Space Grotesk',sans-serif;font-size:9px;font-weight:700;text-transform:uppercase;letter-spacing:1.4px;color:var(--txm);margin:8px 0 4px;display:flex;align-items:center;gap:5px;}
.plat-group-hd.tested{color:var(--ok);}
.plat-group-hd.untested{color:var(--wa);}
.plat-it.untested{opacity:.55;}
.plat-it.untested.on{opacity:1;}
.plat-it.untested .plat-ic::after{content:'🧪';position:absolute;top:-4px;right:-4px;font-size:8px;}
.plat-it{position:relative;}
```

- [ ] **Step 2: Rewrite `initPlats()` to emit two groups**

Replace the whole `initPlats()` function with:
```javascript
function initPlats() {
  const g=document.getElementById('platGrid');
  g.innerHTML='';
  const groups=[
    {tier:'verified', label:'✓ Tested & verified', cls:'tested'},
    {tier:'untested', label:'🧪 Not yet tested', cls:'untested'},
  ];
  groups.forEach(grp=>{
    const items=PLATS.filter(p=>p.tier===grp.tier);
    if(!items.length)return;
    const hd=document.createElement('div');
    hd.className='plat-group-hd '+grp.cls;
    hd.textContent=grp.label;
    hd.style.gridColumn='1 / -1';
    g.appendChild(hd);
    items.forEach(p=>{
      const d=document.createElement('div');
      d.className='plat-it'+(p.tier==='untested'?' untested':'')+(activePlats.has(p.id)?' on':'');
      d.id='pl-'+p.id;
      d.onclick=()=>togPlat(p.id,d);
      d.innerHTML=`<div class="plat-ic" style="background:${p.bg}22;color:${p.bg};">${p.ic}</div><div class="plat-nm">${p.nm}</div>`;
      g.appendChild(d);
    });
  });
}
```

- [ ] **Step 3: Verify**

Reload the app, open the Platforms tab. Expected: a green "✓ Tested & verified" header above the 8 verified tiles, then an amber "🧪 Not yet tested" header above the 6 untested tiles; untested tiles look dimmer and carry a small 🧪 mark. Toggling any tile still works and persists after reload.

- [ ] **Step 4: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: split platform grid into tested/untested groups"
```

### Task 1.3: Group the export-format dropdown with optgroups + tier note

**Files:** Modify `metagen/MetaGen.html` — `renderExpFmt()` and `renderPlatInfo()`.

- [ ] **Step 1: Rewrite `renderExpFmt()` to use optgroups**

Replace the whole `renderExpFmt()` function with:
```javascript
function renderExpFmt(){
  const sel=document.getElementById('expFmt');
  const cur=sel.value;
  sel.innerHTML='';
  const active=[...activePlats,'General'].filter((v,i,a)=>a.indexOf(v)===i&&PLAT_SPECS[v]);
  const verified=active.filter(id=>!isUntested(id));
  const untested=active.filter(id=>isUntested(id));
  const addGroup=(label,ids)=>{
    if(!ids.length)return;
    const og=document.createElement('optgroup');
    og.label=label;
    ids.forEach(id=>{
      const o=document.createElement('option');
      o.value=id; o.textContent=PLAT_SPECS[id].name;
      og.appendChild(o);
    });
    sel.appendChild(og);
  };
  addGroup('✓ Tested & verified', verified);
  addGroup('🧪 Not yet tested', untested);
  if([...sel.options].some(o=>o.value===cur)) sel.value=cur;
  renderPlatInfo();
}
```

- [ ] **Step 2: Add a tier warning line in `renderPlatInfo()`**

In `renderPlatInfo()`, find the closing template-literal line that renders `sp.warn ? ... : ...` and insert a tier banner just before `document.getElementById('platInfo').innerHTML=`. Replace:
```javascript
  document.getElementById('platInfo').innerHTML=`
    <div class="ib-title">${sp.name}</div>
```
with:
```javascript
  const tierNote = isUntested(id)
    ? `<div class="ib-note warn">🧪 This format has not been tested against a real upload yet — verify the CSV before submitting.</div>`
    : '';
  document.getElementById('platInfo').innerHTML=`
    <div class="ib-title">${sp.name}${isUntested(id)?' <span style="font-size:9px;color:var(--wa);">(untested)</span>':''}</div>
    ${tierNote}
```

- [ ] **Step 3: Verify**

Reload. Activate one untested platform (e.g. iStock) in the Platforms tab. In the Export Format dropdown, confirm two optgroups appear and iStock sits under "🧪 Not yet tested". Select it → the spec box shows the amber untested banner. Select a verified one (Adobe) → no banner.

- [ ] **Step 4: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: group export dropdown by tier + untested spec banner"
```

### Task 1.4: Warn when exporting an untested format

**Files:** Modify `metagen/MetaGen.html` — `validateExport()` and the two export functions.

- [ ] **Step 1: Add an untested warning inside `validateExport()`**

In `validateExport(fmtId,cfg)`, immediately after `const warnings=[];` add:
```javascript
  if(isUntested(fmtId)) warnings.push(`${sp.name}: format not yet verified against a real upload — double-check before submitting`);
```

- [ ] **Step 2: Verify**

Reload, generate one result (or load a session in Phase 4), select iStock, click `↓ CSV`. Expected: the validation banner shows the "not yet verified" warning. Export still downloads the file (warning is advisory, not blocking).

- [ ] **Step 3: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: warn on export of untested platform format"
```

---

## Phase 2 — MetaGen: visual bug fixes + version badge

### Task 2.1: Fix the invisible logo gradient

**Files:** Modify `metagen/MetaGen.html` CSS.

There are two `.logo-tx` rules. The base one (search `.logo-tx{font-family`) uses `linear-gradient(90deg,#fff 30%,var(--ac))` — white text on a near-white header = invisible. A later premium override (search `.logo-tx{background:linear-gradient(90deg,#2d2a26 25%`) already sets a dark gradient.

- [ ] **Step 1: Fix the base rule**

Replace `background:linear-gradient(90deg,#fff 30%,var(--ac));` (in the first `.logo-tx` rule) with `background:linear-gradient(90deg,var(--tx) 25%,var(--ac));`

- [ ] **Step 2: Verify**

Reload. The "MetaGen" wordmark in the header is clearly legible (dark → amber gradient), not washed out.

- [ ] **Step 3: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: fix invisible logo gradient on light header"
```

### Task 2.2: Replace stray old-theme green accents

**Files:** Modify `metagen/MetaGen.html` CSS. The app theme is amber (`--ac:#c8891a`), but three spots use leftover teal-green `rgba(0,229,160,...)`.

- [ ] **Step 1: Replace each occurrence**

Find and replace (each is unique enough to edit individually):
- In `input[type=range]::-webkit-slider-thumb{...box-shadow:0 0 8px rgba(0,229,160,.35);}` → `rgba(200,137,26,.35)`
- In `.drop-ico{...background:rgba(0,229,160,.1);...}` → `rgba(200,137,26,.1)`
- In `.drop-ico svg{...stroke:var(--ac);...}` — already amber, leave it.

Then search the whole file for `0,229,160` to confirm none remain (the `.drop-zone` premium override already uses amber).

- [ ] **Step 2: Verify**

Reload. The slider thumb glow and the upload-cloud icon background are amber-toned, consistent with the rest of the UI. `grep`/search for `0,229,160` returns nothing.

- [ ] **Step 3: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: replace leftover teal accents with amber theme"
```

### Task 2.3: Add an app version badge

**Files:** Modify `metagen/MetaGen.html` — header markup + a JS constant.

- [ ] **Step 1: Add the constant**

Near the top of the main `<script>` (just after `let curProv = 'claude';` or at the top of the providers block), add:
```javascript
const APP_VERSION = '1.0.0';
```

- [ ] **Step 2: Show it under the logo subtitle**

In the header, find `<div class="logo-sub">Stock Metadata AI</div>` and replace with:
```html
<div class="logo-sub">Stock Metadata AI · v<span id="appVer">1.0.0</span></div>
```
Then in `init()` (the final one that calls `initPlats()`), add as the first line inside the function:
```javascript
  const av=document.getElementById('appVer'); if(av) av.textContent=APP_VERSION;
```

- [ ] **Step 3: Verify**

Reload. The header subtitle reads "Stock Metadata AI · v1.0.0".

- [ ] **Step 4: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: add v1.0.0 version badge"
```

---

## Phase 3 — MetaGen: update AI models + pricing (June 2026)

> User chose "update all providers to latest." **Model IDs and prices move fast and are account-gated.** During implementation, run a quick `WebSearch` to confirm each ID/price is still current, and keep one proven model per provider as a safety option. The values below are correct as of 2026-06-13.

### Task 3.1: Update the `PROVIDERS` model lists

**Files:** Modify `metagen/MetaGen.html` — `const PROVIDERS = {`.

- [ ] **Step 1: Replace the three `models` arrays**

Claude:
```javascript
    models:[
      {v:'claude-sonnet-4-6',l:'Sonnet 4.6 · Recommended'},
      {v:'claude-haiku-4-5',l:'Haiku 4.5 · Fast & Cheap'},
      {v:'claude-opus-4-8',l:'Opus 4.8 · Best Quality (Expensive)'},
    ]
```
OpenAI (`keyHint` stays `sk-proj-...`):
```javascript
    models:[
      {v:'gpt-5.4',l:'GPT-5.4 · Recommended'},
      {v:'gpt-5.4-mini',l:'GPT-5.4 Mini · Fast & Cheap'},
      {v:'gpt-5.5',l:'GPT-5.5 · Best Quality'},
      {v:'gpt-5.4-nano',l:'GPT-5.4 Nano · Cheapest'},
    ]
```
Gemini (`keyHint` stays `AIzaSy...`):
```javascript
    models:[
      {v:'gemini-3.5-flash',l:'Gemini 3.5 Flash · Recommended'},
      {v:'gemini-3.1-pro-preview',l:'Gemini 3.1 Pro · Best Quality'},
      {v:'gemini-2.5-flash-lite',l:'Gemini 2.5 Flash-Lite · Cheapest & Proven'},
    ]
```

- [ ] **Step 2: Verify**

Reload. Switch the provider buttons (Claude/OpenAI/Gemini) — the model dropdown repopulates with the new lists and no console error.

- [ ] **Step 3: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: update model lists to June 2026 lineups"
```

### Task 3.2: Update `MODEL_PRICING` to match (keys must equal the model IDs above)

**Files:** Modify `metagen/MetaGen.html` — `const MODEL_PRICING = {`.

- [ ] **Step 1: Replace the pricing table body**
```javascript
const MODEL_PRICING = {
  // Claude (Anthropic) — USD per 1M tokens, verified Jun 2026
  'claude-sonnet-4-6': {input: 3.00,  output: 15.00},
  'claude-haiku-4-5':  {input: 1.00,  output: 5.00},
  'claude-opus-4-8':   {input: 5.00,  output: 25.00},
  // OpenAI
  'gpt-5.4':       {input: 2.50, output: 15.00},
  'gpt-5.4-mini':  {input: 0.75, output: 4.50},
  'gpt-5.5':       {input: 5.00, output: 30.00},
  'gpt-5.4-nano':  {input: 0.20, output: 1.25},
  // Gemini
  'gemini-3.5-flash':       {input: 1.50, output: 9.00},
  'gemini-3.1-pro-preview': {input: 2.00, output: 12.00},
  'gemini-2.5-flash-lite':  {input: 0.10, output: 0.40},
};
```

- [ ] **Step 2: Update the Claude API test default model**

In `testApi()`, the Claude branch posts `model:'claude-haiku-4-5-20251001'`. Change it to `model:'claude-haiku-4-5'` (alias is valid and matches the new list).

- [ ] **Step 3: Verify**

Reload. Every model in every provider dropdown has a matching `MODEL_PRICING` key (no key typos). After a real generation (or in console: `calcCost('claude-sonnet-4-6',1000,1000)`) the cost is non-zero. With a valid Claude key, "Test →" turns the dot green.

- [ ] **Step 4: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: update model pricing table to match new models"
```

### Task 3.3: Make `callOpenAI` compatible with GPT-5 request shape

**Files:** Modify `metagen/MetaGen.html` — `callOpenAI()`.

GPT-5 chat-completions models reject the legacy `max_tokens` field and require `max_completion_tokens`. Make the call adapt by model id.

- [ ] **Step 1: Build the body conditionally**

Replace the `body:JSON.stringify({ model:cfg.model, max_tokens:1500, messages:[...] })` block in `callOpenAI` with:
```javascript
    body:JSON.stringify((()=>{
      const body={
        model:cfg.model,
        messages:[{role:'user',content:[
          {type:'image_url',image_url:{url:`data:${mime};base64,${b64}`,detail:'high'}},
          {type:'text',text:buildPrompt(cfg)}
        ]}]
      };
      // GPT-5+ uses max_completion_tokens; older models use max_tokens
      if(/^gpt-5/i.test(cfg.model)) body.max_completion_tokens=1500;
      else body.max_tokens=1500;
      return body;
    })())
```

- [ ] **Step 2: Verify (manual, needs an OpenAI key with GPT-5 access)**

With an OpenAI key, select `gpt-5.4-mini`, upload one small JPG, Generate. Expected: a result row appears with title/description/keywords and a non-zero cost. If the account lacks GPT-5 access the API returns a clear 4xx surfaced via `notif` — in that case the user can fall back to a Gemini/Claude model. Document this in the OpenAI section of the guide.

- [ ] **Step 3: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: send max_completion_tokens for GPT-5 models"
```

### Task 3.4: Verify Gemini 3 request/response shape, add fallback note

**Files:** Inspect `callGemini()` in `metagen/MetaGen.html`. Likely no code change; this task confirms the existing `v1beta/models/{model}:generateContent` shape still works for `gemini-3.5-flash`.

- [ ] **Step 1: Manual check (needs a Gemini key)**

Select `gemini-3.5-flash`, generate one image. Expected: result row + cost. If the response shape differs (no `candidates[0].content.parts`), the catch surfaces an error — then keep `gemini-2.5-flash-lite` as the working default and note the limitation in the guide + CHANGELOG. Do **not** block the release on Gemini 3 working; `gemini-2.5-flash-lite` is the proven fallback already in the list.

- [ ] **Step 2: Commit only if a code change was needed**
```
git add metagen/MetaGen.html && git commit -m "metagen: confirm/adjust Gemini 3 generateContent handling"
```

---

## Phase 4 — MetaGen: Save / Load session

All edits in `metagen/MetaGen.html`. Lets the user keep generated results across browser restarts without re-paying for AI.

### Task 4.1: Add Save / Load buttons to the results header

**Files:** Modify `metagen/MetaGen.html` — results header markup (search `<span class="res-title">Results</span>`).

- [ ] **Step 1: Add buttons + a hidden file input**

In the `.res-hd` block, before the existing `btnClearResults` button, insert:
```html
        <button class="btn-clear-upload" id="btnSaveSession" onclick="saveSession()" disabled title="Save all generated results to a .json file you can reload later" style="border-color:var(--bd2);background:var(--sf2);color:var(--txd);">💾 Save</button>
        <button class="btn-clear-upload" id="btnLoadSession" onclick="document.getElementById('sessionIn').click()" title="Load results from a saved .json session" style="border-color:var(--bd2);background:var(--sf2);color:var(--txd);">📂 Load</button>
```
And next to the existing hidden `fileIn` input near the top of `<body>`, add:
```html
<input type="file" id="sessionIn" accept="application/json,.json" style="display:none">
```

- [ ] **Step 2: Wire the file input change handler**

Where `fileIn`'s change listener is registered (search `getElementById('fileIn').addEventListener('change'`), add right after it:
```javascript
document.getElementById('sessionIn').addEventListener('change',e=>{
  const f=e.target.files[0];
  if(f) loadSession(f);
  e.target.value='';
});
```

- [ ] **Step 3: Enable/disable Save with results**

In `refreshResultsState()`, where it sets `btnClearResults.disabled`, add right after:
```javascript
  const saveBtn=document.getElementById('btnSaveSession');
  if(saveBtn) saveBtn.disabled=isGen||!hasResults;
```

- [ ] **Step 4: Verify (after 4.2 implements the functions)** — deferred; for now just confirm no console error and buttons render (they will throw on click until 4.2). Commit together with 4.2.

### Task 4.2: Implement `saveSession()` and `loadSession()`

**Files:** Modify `metagen/MetaGen.html` — add functions near the LOCAL STORAGE section.

- [ ] **Step 1: Add the two functions**
```javascript
/* ============================
   SESSION SAVE / LOAD
   ============================ */
function saveSession(){
  if(isGen){notif('Wait for generation to finish before saving','err');return;}
  if(!results.length){notif('No results to save','err');return;}
  const payload={
    app:'MetaGen',
    version:APP_VERSION,
    savedAt:new Date().toISOString(),
    results:results.map(r=>({
      fileName:r.file?.name||'',
      title:r.title||'',
      description:r.description||'',
      keywords:normalizeKeywords(r.keywords),
      category:r.category||'',
      _cost:r._cost??null,
      _inputTokens:r._inputTokens??null,
      _outputTokens:r._outputTokens??null
    }))
  };
  const blob=new Blob([JSON.stringify(payload,null,2)],{type:'application/json'});
  const url=URL.createObjectURL(blob);
  const a=document.createElement('a');
  const d=new Date();
  const stamp=`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}_${String(d.getHours()).padStart(2,'0')}${String(d.getMinutes()).padStart(2,'0')}`;
  a.href=url; a.download=`MetaGen_Session_${stamp}.json`; a.click();
  URL.revokeObjectURL(url);
  notif(`Saved ${results.length} result${results.length===1?'':'s'} to session file ✓`,'ok');
}

function loadSession(file){
  const reader=new FileReader();
  reader.onload=e=>{
    let data;
    try{ data=JSON.parse(e.target.result); }
    catch(err){ notif('That file is not valid JSON','err'); return; }
    if(!data||data.app!=='MetaGen'||!Array.isArray(data.results)){
      notif('Not a MetaGen session file','err'); return;
    }
    if(results.length && !confirm(`Replace the ${results.length} result(s) currently shown with ${data.results.length} from this session?`)) return;
    results=data.results.map(m=>{
      const meta=normalizeMetadata({
        title:m.title, description:m.description, keywords:m.keywords, category:m.category
      });
      return {
        file:{name:m.fileName||'(restored)'},
        id:crypto.randomUUID(),
        status:'ok',
        preview:null,
        restored:true,
        _cost:m._cost??null,
        _inputTokens:m._inputTokens??null,
        _outputTokens:m._outputTokens??null,
        ...meta
      };
    });
    files=[];
    renderChips();
    recalcSessionTotals();
    refreshResultsState({rebuild:true});
    notif(`Loaded ${results.length} result${results.length===1?'':'s'} from session ✓`,'ok');
  };
  reader.readAsText(file);
}
```

- [ ] **Step 2: Skip regen + thumbnail for restored rows**

In `appendRow()`, the regen button and thumbnail assume a real `File`. Guard them:
- Where the thumbnail `if(f.preview){...}` block is — it already only renders when `f.preview` exists, so restored rows (preview=null) simply show no thumb. Good, no change.
- For the regen button, find `regenBtn.addEventListener('click',()=>regenSingle(idx));` and wrap creation so restored rows disable it. Replace the regen button creation block with:
```javascript
  const regenBtn=document.createElement('button');
  regenBtn.type='button';
  regenBtn.className='edit-btn';
  if(f.restored){
    regenBtn.title='Re-generate needs the original image (not stored in sessions)';
    regenBtn.textContent='🔄';
    regenBtn.disabled=true;
    regenBtn.style.opacity='.35';
    regenBtn.style.cursor='not-allowed';
  }else{
    regenBtn.title='Re-generate this image';
    regenBtn.textContent='🔄';
    regenBtn.addEventListener('click',()=>regenSingle(idx));
  }
```

- [ ] **Step 3: Verify**

Reload. Generate (or hand-build) 2 results. Click `💾 Save` → a `MetaGen_Session_*.json` downloads. Reload the page (results gone). Click `📂 Load`, pick the file → the 2 rows reappear with title/description/keywords and cost; the 🔄 button is greyed out; `↓ CSV` still exports a valid file for a verified platform. Loading a non-JSON or non-MetaGen file shows an error and leaves the table untouched.

- [ ] **Step 4: Commit**
```
git add metagen/MetaGen.html && git commit -m "metagen: add session save/load (results survive reloads)"
```

---

## Phase 5 — Dreamstime tool: PowerShell (`dreamstime-embed.ps1`)

All edits in `dreamstime-tool/dreamstime-embed.ps1`. **Do not change the ExifTool write/verify field mapping.**

### Task 5.1: Rename the `$args` automatic-variable shadow

**Files:** Modify `dreamstime-tool/dreamstime-embed.ps1` — `Invoke-ExifToolWrite` and `Invoke-ExifToolVerify`.

`$args` is a PowerShell automatic variable; the functions reuse the name for the ExifTool argument list. It works today but is fragile and confusing. Rename to `$exifArgs` — **only the local variable name**, not the values.

- [ ] **Step 1: In `Invoke-ExifToolWrite`** rename the local `$args` to `$exifArgs` in all four places (`$args = @(`, the two `$args += ...`, and `& $ExifTool @args`). Final invoke becomes `& $ExifTool @exifArgs`.

- [ ] **Step 2: In `Invoke-ExifToolVerify`** rename its local `$args = @(` and `& $ExifTool @args` to `$exifArgs` / `@exifArgs`.

- [ ] **Step 3: Verify (syntax)**

Run: `powershell -NoProfile -Command "$null = [scriptblock]::Create((Get-Content -Raw 'dreamstime-tool/dreamstime-embed.ps1')); 'parse-ok'"`
Expected: prints `parse-ok` with no parser error.

- [ ] **Step 4: Commit**
```
git add dreamstime-tool/dreamstime-embed.ps1 && git commit -m "dreamstime: rename \$args shadow to \$exifArgs"
```

### Task 5.2: Add an optional `-ProgressFile` parameter

**Files:** Modify `dreamstime-tool/dreamstime-embed.ps1` — `param(...)` block + the main `foreach($row in $rows)` loop.

- [ ] **Step 1: Add the parameter**

In the `param(...)` block, after `[switch]$DryRun`, add:
```powershell
  ,
  [string]$ProgressFile = ''
```

- [ ] **Step 2: Write progress at the top of each row iteration**

Inside `foreach($row in $rows){`, as the first statements, add:
```powershell
  $rowIndex = $report.Count + 1
  if(-not [string]::IsNullOrWhiteSpace($ProgressFile)){
    $pfLine = "$rowIndex|$($rows.Count)|$filename|processing"
    try { Set-Content -LiteralPath $ProgressFile -Value $pfLine -Encoding UTF8 } catch {}
  }
```
Note: `$filename` is computed two lines below currently — move the `$filename = Get-FirstValue ...` assignment to be the very first line of the loop body (before the progress write) so the filename is available. Verify the reordering keeps `$title`, `$description`, `$keywords` assignments intact right after.

- [ ] **Step 3: Write a final summary line after the loop**

After the `foreach` loop closes and before the report export, add:
```powershell
if(-not [string]::IsNullOrWhiteSpace($ProgressFile)){
  try { Set-Content -LiteralPath $ProgressFile -Value "$($rows.Count)|$($rows.Count)|done|complete" -Encoding UTF8 } catch {}
}
```

- [ ] **Step 4: Verify**

Run the fixture test in Task 5.4 — it covers `-ProgressFile`. For now confirm parse-ok again (Task 5.1 Step 3).

- [ ] **Step 5: Commit**
```
git add dreamstime-tool/dreamstime-embed.ps1 && git commit -m "dreamstime: add -ProgressFile live status output"
```

### Task 5.3: (No change needed for Dry Run) confirm `-DryRun` already short-circuits ExifTool

**Files:** Read only.

- [ ] **Step 1: Confirm**

`-DryRun` already sets `$exifTool = '(dry-run; ExifTool not required)'`, skips `New-Item` for the output dir, and per-row sets `status='dry-run'` without copying or writing. The HTA Dry-Run button (Task 6.5) reuses this. No code change. Note in the guide that Dry Run reports CSV↔image matching only.

### Task 5.4: Fixture smoke test for the PS1

**Files:** Create a temp fixture under the OS temp dir (not committed).

- [ ] **Step 1: Build a fixture and run dry-run + real run**

Run this PowerShell block (it self-cleans; requires internet only if ExifTool isn't already present — the script auto-downloads it):
```powershell
$fx = Join-Path $env:TEMP ("dt-fixture-" + [guid]::NewGuid().ToString('N'))
$img = Join-Path $fx 'images'; New-Item -ItemType Directory -Force $fx,$img | Out-Null
# 1x1 JPEG
$bytes=[Convert]::FromBase64String('/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFAABAAAAAAAAAAAAAAAAAAAAAv/EABQQAQAAAAAAAAAAAAAAAAAAAAD/xAAUAQEAAAAAAAAAAAAAAAAAAAAA/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAwDAQACEQMRAD8AvwA//9k=')
[IO.File]::WriteAllBytes((Join-Path $img 'a.jpg'),$bytes)
@'
Filename,Image Name,Description,keywords
a.jpg,Test Title,AI-generated image. A tiny test photo.,"ai generated,test,sample,red,square,minimal"
'@ | Set-Content -LiteralPath (Join-Path $fx 'MetaGen_Dreamstime_2026-06-13.csv') -Encoding UTF8

$csv = Join-Path $fx 'MetaGen_Dreamstime_2026-06-13.csv'
$out = Join-Path $fx 'out'
$prog = Join-Path $fx 'progress.txt'

# Dry run
powershell -NoProfile -ExecutionPolicy Bypass -File 'dreamstime-tool/dreamstime-embed.ps1' -Csv $csv -ImagesDir $img -OutDir $out -DryRun -ProgressFile $prog
"DRYRUN progress: $(Get-Content $prog -Raw)"

# Real run
powershell -NoProfile -ExecutionPolicy Bypass -File 'dreamstime-tool/dreamstime-embed.ps1' -Csv $csv -ImagesDir $img -OutDir $out -AiMode ai -AiModel 'Adobe Firefly' -ProgressFile $prog
"REAL progress: $(Get-Content $prog -Raw)"
Get-ChildItem $out
Import-Csv (Join-Path $out 'dreamstime-embed-report.csv') | Format-Table Filename,Status,Keywords,Title -Auto
# cleanup
Remove-Item -Recurse -Force $fx
```

- [ ] **Step 2: Confirm expected output**

Expected: dry run reports `Processed: 1`, progress file ends `done|complete`; real run copies `a.jpg` into `out/`, writes `dreamstime-embed-report.csv` with `Status = ok` (or `verify-warning` if the 1×1 strips some tags — acceptable), and the embed metadata is readable. No exceptions thrown. Source `images/a.jpg` is byte-identical (never modified).

- [ ] **Step 3: No commit** (fixture is temp/uncommitted). If a bug surfaced, fix the PS1, re-run, then commit the fix.

---

## Phase 6 — Dreamstime tool: HTA (`Dreamstime Metadata Tool.hta`)

All edits in `dreamstime-tool/Dreamstime Metadata Tool.hta`.

### Task 6.1: Locate the script and icon relative to the HTA (remove hardcoded `GPT META gen`)

**Files:** Modify `.hta` — the `<hta:application icon=...>` attribute and the `SCRIPT_PATH` / `DEFAULT_FOLDER` constants + `init()`.

- [ ] **Step 1: Make the taskbar icon relative**

In `<hta:application ... icon="C:\Users\Darks\Documents\GPT META gen\assets\dreamstime-tool-icon.ico" ...>` change the icon value to `assets\dreamstime-tool-icon.ico`. If `mshta` fails to load a relative HTA icon on the target machine (it sometimes requires absolute), the test in Step 4 will show a missing icon only — the app still runs; in that case fall back to computing it in `init()` (see Step 3) is not possible for the window chrome, so just leave the relative path; the in-window `<img>` logo already works relatively.

- [ ] **Step 2: Replace the hardcoded constants with runtime resolution**

Replace:
```javascript
var SCRIPT_PATH = "C:\\Users\\Darks\\Documents\\GPT META gen\\dreamstime-embed.ps1";
var DEFAULT_FOLDER = "C:\\Users\\Darks\\Pictures\\2026 RE Submit Stock\\Pre Submit Vecteezy";
```
with:
```javascript
var APP_DIR = "";          // folder containing this .hta — resolved in init()
var SCRIPT_PATH = "";      // APP_DIR\dreamstime-embed.ps1
var SETTINGS_PATH = "";    // %APPDATA%\DreamstimeMetadataTool\settings.txt
```

- [ ] **Step 3: Compute `APP_DIR` at the top of `init()`**

In `init()`, right after the `shell`/`fso` ActiveX setup succeeds (after the try/catch), add:
```javascript
  APP_DIR = appDir();
  SCRIPT_PATH = APP_DIR + "\\dreamstime-embed.ps1";
  SETTINGS_PATH = shell.ExpandEnvironmentStrings("%APPDATA%") + "\\DreamstimeMetadataTool\\settings.txt";
```
And add this helper function (above `init()`):
```javascript
function appDir(){
  // location.pathname is like /C:/Users/.../Dreamstime%20Metadata%20Tool.hta
  var p = String(location.pathname || "");
  try { p = decodeURIComponent(p); } catch(e){}
  p = p.replace(/^\//, "").replace(/\//g, "\\");
  var slash = p.lastIndexOf("\\");
  return slash > 0 ? p.substring(0, slash) : p;
}
```

- [ ] **Step 4: Verify**

Double-click the `.hta`. Expected: it opens (window icon may or may not show depending on mshta), the in-window logo renders, and the missing-script error does NOT appear (because `SCRIPT_PATH` now points next to the HTA). Temporarily check by adding `alert(SCRIPT_PATH)` in init during testing, then remove.

- [ ] **Step 5: Commit**
```
git add "dreamstime-tool/Dreamstime Metadata Tool.hta" && git commit -m "dreamstime-hta: resolve script + icon relative to the app folder"
```

### Task 6.2: Persist settings across runs (folder, AI mode/model, sound)

**Files:** Modify `.hta` — add settings read/write helpers; call them in `init()`, `runEmbed()`, and on control changes.

- [ ] **Step 1: Add settings helpers**

Add these functions (near the other helpers):
```javascript
function readSettings(){
  var s = {};
  try{
    if(!fso.FileExists(SETTINGS_PATH)) return s;
    var f = fso.OpenTextFile(SETTINGS_PATH, 1, false, -1);
    var txt = f.ReadAll(); f.Close();
    var lines = String(txt||"").split(/\r?\n/);
    for(var i=0;i<lines.length;i++){
      var eq = lines[i].indexOf("=");
      if(eq>0) s[lines[i].substring(0,eq)] = lines[i].substring(eq+1);
    }
  }catch(e){}
  return s;
}
function writeSettings(){
  try{
    var dir = shell.ExpandEnvironmentStrings("%APPDATA%") + "\\DreamstimeMetadataTool";
    if(!fso.FolderExists(dir)) fso.CreateFolder(dir);
    var lines = [
      "lastFolder=" + (currentFolder||""),
      "aiMode=" + ($("modeAi").checked ? "ai" : "nonai"),
      "aiModel=" + $("model").value,
      "sound=" + ($("soundDone").checked ? "1" : "0")
    ];
    var f = fso.CreateTextFile(SETTINGS_PATH, true, true);
    f.Write(lines.join("\r\n")); f.Close();
  }catch(e){}
}
```

- [ ] **Step 2: Apply settings in `init()`**

In `init()`, replace the block:
```javascript
  if(fso.FolderExists(DEFAULT_FOLDER)){
    setFolder(DEFAULT_FOLDER);
  }
```
with:
```javascript
  var s = readSettings();
  if(s.aiMode === "nonai"){ $("modeNonAi").checked = true; } else { $("modeAi").checked = true; }
  if(s.aiModel){ var opts=$("model").options; for(var i=0;i<opts.length;i++){ if(opts[i].value===s.aiModel||opts[i].text===s.aiModel){ $("model").selectedIndex=i; break; } } }
  if(s.sound === "0"){ $("soundDone").checked = false; }
  if(s.lastFolder && fso.FolderExists(s.lastFolder)){
    setFolder(s.lastFolder);
  } else {
    setStatus("Choose your work folder to begin.", false);
  }
```

- [ ] **Step 3: Save on run and on control change**

In `runEmbed()`, right after it confirms the CSV exists and before building the command, add `writeSettings();`. Also add `onchange="writeSettings()"` to the `#model` `<select>` and the `#soundDone` checkbox, and call `writeSettings()` at the end of `setFolder()`.

- [ ] **Step 4: Verify**

Open the HTA, choose a work folder, switch AI model, untick the sound box, run (or just close). Reopen → the same folder is preselected, the model and sound checkbox match what you left. Settings file exists at `%APPDATA%\DreamstimeMetadataTool\settings.txt`.

- [ ] **Step 5: Commit**
```
git add "dreamstime-tool/Dreamstime Metadata Tool.hta" && git commit -m "dreamstime-hta: persist folder/model/sound across runs"
```

### Task 6.3: Live progress while embedding

**Files:** Modify `.hta` — `runEmbed()` and `poll()`.

- [ ] **Step 1: Pass a progress file to the PS1**

In `runEmbed()`, before building `cmd`, add:
```javascript
  var progFile = tempBase("dreamstime-progress") + ".txt";
```
and append ` -ProgressFile ` + `q(progFile)` to the `cmd` string. Store it for polling: add `window._progFile = progFile;` right after.

- [ ] **Step 2: Read progress on each poll tick**

In `poll(exec)`, inside the `if(exec.Status === 0){ ... }` branch (still running), before re-scheduling the timeout, add:
```javascript
    try{
      if(window._progFile && fso.FileExists(window._progFile)){
        var pf = fso.OpenTextFile(window._progFile, 1, false, -1);
        var line = pf.ReadAll(); pf.Close();
        var parts = String(line||"").split("|");
        if(parts.length>=3){
          if(parts[3]==="complete" || parts[1]===parts[0]){
            setRunStatus("Finishing up...", false);
          } else {
            setRunStatus("Embedding image " + parts[0] + " of " + parts[1] + " — " + parts[2], false);
          }
        }
      }
    }catch(e){}
```

- [ ] **Step 3: Clean up the progress file when done**

In `poll()`, in the finished branch (after reading StdOut/StdErr), add:
```javascript
    try{ if(window._progFile && fso.FileExists(window._progFile)) fso.DeleteFile(window._progFile, true); }catch(e){}
```

- [ ] **Step 4: Verify**

Put a few JPGs + a `MetaGen_Dreamstime_*.csv` in a folder, point the HTA at it, run. Expected: the status line updates "Embedding image X of Y — filename.jpg" during the run, then "Done. Upload images from the output folder." and the output folder opens. The log box still shows full stdout at the end.

- [ ] **Step 5: Commit**
```
git add "dreamstime-tool/Dreamstime Metadata Tool.hta" && git commit -m "dreamstime-hta: show live per-image progress"
```

### Task 6.4: Replace the "send Codex a screenshot" copy with neutral guidance

**Files:** Modify `.hta` (and the BAT in Task 7.3).

- [ ] **Step 1: Reword failure messaging**

In the `.hta`, find any user-facing "Codex"/developer-name strings (e.g. in error notifications) and replace with neutral text like "Something went wrong. Check the log box below, or open an issue on the project's GitHub page." (The `.hta` currently says "Check the log box below." — confirm and align wording; main offender is the BAT, fixed in Task 7.3.)

- [ ] **Step 2: Verify** — grep the `.hta` for `Codex`; expect zero matches.

- [ ] **Step 3: Commit** (fold into Task 6.5 commit if no standalone change).

### Task 6.5: Add a Dry-Run button

**Files:** Modify `.hta` — action bar markup + a `runDryRun()` function.

- [ ] **Step 1: Add the button**

In the `.actionGrid`, add a third control. Change the grid to fit three buttons (update `.actionGrid{grid-template-columns:1fr 150px 150px;...}` in CSS) and add before `openBtn`:
```html
    <button id="dryBtn" class="btn2" onclick="runDryRun()" title="Preview CSV-to-image matching without writing anything">🧪 Dry Run</button>
```

- [ ] **Step 2: Implement `runDryRun()`**

Add a function that mirrors `runEmbed()` but passes `-DryRun`, does not create/open an output folder, and shows the match summary from stdout in the log box:
```javascript
function runDryRun(){
  if(running){ return; }
  if(!currentFolder || !fso.FolderExists(currentFolder)){ setError("Choose a valid work folder first."); return; }
  if(!currentCsv || !fso.FileExists(currentCsv)){ findLatestCsv(); }
  if(!currentCsv || !fso.FileExists(currentCsv)){ setError("Dreamstime CSV is missing. Choose a CSV or export one from MetaGen."); return; }
  if(!fso.FileExists(SCRIPT_PATH)){ setError("Missing script: " + SCRIPT_PATH); return; }
  $("log").value = "Dry run — checking which CSV rows match images. Nothing will be written.\r\n";
  $("runBtn").disabled = true; $("dryBtn").disabled = true; running = true;
  setRunStatus("Dry run in progress...", false);
  var cmd = "powershell -NoProfile -ExecutionPolicy Bypass -File " + q(SCRIPT_PATH) +
    " -Csv " + q(currentCsv) + " -ImagesDir " + q(currentFolder) +
    " -OutDir " + q(currentFolder + "\\__dryrun_unused") + " -DryRun";
  try{
    var exec = shell.Exec(cmd);
    pollDry(exec);
  }catch(e){ running=false; $("runBtn").disabled=false; $("dryBtn").disabled=false; setError("Could not start dry run: " + e.message); }
}
function pollDry(exec){
  if(exec.Status === 0){ window.setTimeout(function(){ pollDry(exec); }, 500); return; }
  var out=""; var err="";
  try{ out = exec.StdOut.ReadAll(); }catch(e1){}
  try{ err = exec.StdErr.ReadAll(); }catch(e2){}
  $("log").value = (out||"") + (err ? "\r\nERROR:\r\n"+err : "");
  running=false; $("runBtn").disabled=false; $("dryBtn").disabled=false;
  setRunStatus(exec.ExitCode===0 ? "Dry run complete — review the log, then press Embed Metadata." : "Dry run failed — check the log.", exec.ExitCode===0);
}
```

- [ ] **Step 3: Verify**

With a folder + CSV selected, click 🧪 Dry Run. Expected: the log shows the processed/skipped counts; no `Dreamstime Ready` folder is created; the green Embed button remains usable afterward. (The PS1 dry-run path does not write to `-OutDir`, so the `__dryrun_unused` folder is never created.)

- [ ] **Step 4: Commit**
```
git add "dreamstime-tool/Dreamstime Metadata Tool.hta" && git commit -m "dreamstime-hta: add Dry Run button + neutral error copy"
```

---

## Phase 7 — Dreamstime tool: BAT (`Dreamstime Embed - Double Click.bat`)

All edits in `dreamstime-tool/Dreamstime Embed - Double Click.bat`.

### Task 7.1: Resolve the PS1 next to the BAT, with a clear override

**Files:** Modify the BAT — the `set "SCRIPT=..."` line.

- [ ] **Step 1: Replace hardcoded path with layered resolution**

Replace:
```bat
set "SCRIPT=C:\Users\Darks\Documents\GPT META gen\dreamstime-embed.ps1"
```
with:
```bat
rem ── Where is dreamstime-embed.ps1? ──────────────────────────────
rem 1) Same folder as this file (default — keep them together)
rem 2) Edit INSTALL_DIR below if you move the .ps1 elsewhere
set "INSTALL_DIR=%USERPROFILE%\Documents\Fable Metagen\dreamstime-tool"
set "SCRIPT=%THIS%\dreamstime-embed.ps1"
if not exist "%SCRIPT%" set "SCRIPT=%INSTALL_DIR%\dreamstime-embed.ps1"
if not exist "%SCRIPT%" (
  echo.
  echo Could not find dreamstime-embed.ps1.
  echo Put this .bat in the same folder as dreamstime-embed.ps1,
  echo or edit the INSTALL_DIR line inside this .bat.
  echo.
  pause
  exit /b 1
)
```

- [ ] **Step 2: Verify**

Place the BAT next to the PS1 with a test CSV + images, double-click. Expected: it finds the script via `%THIS%` and runs. Temporarily rename the PS1 → it prints the clear "Could not find" message and pauses (does not crash).

- [ ] **Step 3: Commit**
```
git add "dreamstime-tool/Dreamstime Embed - Double Click.bat" && git commit -m "dreamstime-bat: locate script next to bat with INSTALL_DIR override"
```

### Task 7.2: Hoist AI mode/model to editable variables at the top

**Files:** Modify the BAT.

- [ ] **Step 1: Add config vars near the top** (after `set "THIS=..."`):
```bat
rem ── Defaults (edit if needed) ───────────────────────────────────
set "AI_MODE=ai"
set "AI_MODEL=Adobe Firefly"
```
Then change the powershell invocation's `-AiMode "ai" -AiModel "Adobe Firefly"` to `-AiMode "%AI_MODE%" -AiModel "%AI_MODEL%"`.

- [ ] **Step 2: Verify** — double-click run still embeds with AI mode; editing `AI_MODEL` to e.g. `Midjourney 5` changes the embedded CreatorTool.

- [ ] **Step 3: Commit**
```
git add "dreamstime-tool/Dreamstime Embed - Double Click.bat" && git commit -m "dreamstime-bat: hoist AI mode/model to top-of-file variables"
```

### Task 7.3: Replace developer-name failure text

**Files:** Modify the BAT.

- [ ] **Step 1:** Replace `echo Something went wrong. Please send Codex a screenshot of this window.` with:
```bat
  echo Something went wrong. Read the messages above, or open an issue
  echo on the project's GitHub page with a copy of this window.
```

- [ ] **Step 2: Verify** — `findstr /I Codex "Dreamstime Embed - Double Click.bat"` returns nothing.

- [ ] **Step 3: Commit**
```
git add "dreamstime-tool/Dreamstime Embed - Double Click.bat" && git commit -m "dreamstime-bat: neutral failure message"
```

---

## Phase 8 — Documentation

### Task 8.1: `docs/csv-formats.md` — platform spec reference

**Files:** Create `docs/csv-formats.md`.

- [ ] **Step 1: Write the file** with: a table of all 14 platforms (Name, CSV headers, separator, BOM yes/no, title max, desc support+max, keyword min–max, keyword separator, **Tested status + date**). Verified: Adobe, Shutterstock, Freepik, Dreamstime, 123RF, Pond5, Vecteezy — mark "✅ Tested 2026-06". General — "✅ Safe universal format". Others — "🧪 Untested". Pull the exact numbers from `PLAT_SPECS` in `MetaGen.html` (do not invent). Add a short "How to add/verify a new platform" note pointing at `PLATS` (`tier`) and `PLAT_SPECS`.

- [ ] **Step 2: Verify** — numbers match `PLAT_SPECS`. Commit:
```
git add docs/csv-formats.md && git commit -m "docs: add CSV format reference with tested status"
```

### Task 8.2: `docs/metagen-guide.th.md` — Thai user guide for MetaGen

**Files:** Create `docs/metagen-guide.th.md`.

- [ ] **Step 1: Write (Thai)** covering: opening `metagen/MetaGen.html` (double-click, runs fully in-browser); choosing provider + entering API key (note: key stays in the browser, never sent to any server but the AI provider); sliders (title/desc/keywords); keyword rank colors; selecting platforms (tested vs untested groups); generating; cost tracker; editing rows; **Save/Load session**; exporting CSV (per platform + "All"); and **how to promote an untested platform to tested** (test the CSV upload, then change its `tier` to `'verified'` in `PLATS`). Keep it task-oriented and screenshot-ready (describe where things are).

- [ ] **Step 2: Commit**
```
git add docs/metagen-guide.th.md && git commit -m "docs: add Thai MetaGen user guide"
```

### Task 8.3: `docs/dreamstime-tool-guide.th.md` — Thai guide for the Dreamstime tool

**Files:** Create `docs/dreamstime-tool-guide.th.md`.

- [ ] **Step 1: Write (Thai)** covering: the workflow (MetaGen → export Dreamstime CSV → put CSV in the image folder → run the tool); two ways to run (double-click the `.hta` for the GUI, or the `.bat` for no-GUI); the three GUI steps; **Dry Run**; AI vs non-AI mode and disclosure text; that originals are never modified (a new "Dreamstime Ready" folder is created); reading `dreamstime-embed-report.csv` (status meanings: ok / missing / ambiguous / invalid / verify-warning); and troubleshooting (ExifTool auto-download needs internet once; if Windows blocks the HTA, open by double-click not in a browser; execution-policy is bypassed by the launcher).

- [ ] **Step 2: Commit**
```
git add docs/dreamstime-tool-guide.th.md && git commit -m "docs: add Thai Dreamstime tool guide"
```

### Task 8.4: `README.md` (EN) + `README.th.md` (TH)

**Files:** Create `README.md`, `README.th.md`.

- [ ] **Step 1: `README.md`** — project title, one-paragraph overview of the two tools and how they connect (MetaGen makes CSVs; the Dreamstime tool embeds the Dreamstime CSV into image copies). A **platform status table** (✅ tested vs 🧪 untested). Quick start for each tool. A **Security note**: API keys live in the browser/local only and go straight to the chosen AI provider; run locally; don't commit keys. Repo layout. Links to the `docs/` guides. A short Roadmap (the out-of-scope items from the spec §12). License line.

- [ ] **Step 2: `README.th.md`** — Thai counterpart, fuller (it's the main guide for the user), including a "ย้ายมาจากโฟลเดอร์เก่า" note: old shortcuts pointing at `GPT META gen` must be re-pointed; keep the old folder as backup until everything is verified.

- [ ] **Step 3: Verify** — both render on GitHub (valid Markdown, tables aligned). Commit:
```
git add README.md README.th.md && git commit -m "docs: add bilingual README"
```

### Task 8.5: `CHANGELOG.md` + `LICENSE`

**Files:** Create `CHANGELOG.md`, `LICENSE`.

- [ ] **Step 1: `CHANGELOG.md`** — `## [1.0.0] - 2026-06-13` summarizing every change this plan made (restructure, platform tiers, logo/theme fixes, model+pricing update with the note that GPT-5/Gemini-3 access is account-dependent and `gemini-2.5-flash-lite` is the proven fallback, session save/load, Dreamstime path auto-detection, settings persistence, live progress, dry run, docs). List explicitly any model that could not be verified working at implementation time.

- [ ] **Step 2: `LICENSE`** — MIT. Resolve the copyright holder from git config: run `git config user.name`; use that name (and year 2026). If a GitHub username is preferred, ask the user; default to the git user.name.

- [ ] **Step 3: Commit**
```
git add CHANGELOG.md LICENSE && git commit -m "docs: add CHANGELOG v1.0.0 and MIT LICENSE"
```

---

## Phase 9 — Publish to private GitHub

### Task 9.1: Install GitHub CLI

- [ ] **Step 1: Install via winget**

Run: `winget install --id GitHub.cli --source winget --accept-source-agreements --accept-package-agreements`
If `winget` is unavailable, tell the user and fall back to manual repo creation (Task 9.3 alt).

- [ ] **Step 2: Verify**

Open a fresh shell (PATH refresh) and run: `gh --version`
Expected: prints a version. If "not recognized", the current shell hasn't picked up PATH — use the full path `"$env:LOCALAPPDATA\Programs\GitHub CLI\gh.exe"` or restart the shell.

### Task 9.2: Authenticate

- [ ] **Step 1:** Run `gh auth status`. If not logged in, run `gh auth login` (this is interactive — **hand off to the user** to complete the browser/device login, since interactive prompts can't be driven here). Confirm with `gh auth status` afterward.

### Task 9.3: Create the private repo and push

- [ ] **Step 1: Final pre-push check**

Run: `git status` (clean), `git log --oneline` (all phase commits present), and confirm `.gitignore` excludes `graphify-out/`, `tools/`, exported CSVs, and `Dreamstime Ready */`.

- [ ] **Step 2: Create + push**

Run: `gh repo create metagen-stock-tools --private --source . --remote origin --push`
Expected: repo created under the user's account, `main` pushed.

- [ ] **Step 3: Verify**

Run: `gh repo view --web` (opens the repo) or `gh repo view`. Confirm README renders and the folder layout is correct on GitHub.

**Alt (no gh):** create an empty private repo at github.com, then `git remote add origin <url>` and `git push -u origin main` (Git Credential Manager will prompt for auth).

### Task 9.4: Leave the old folder untouched

- [ ] **Step 1:** Do **not** delete `C:\Users\Darks\Documents\GPT META gen`. Note in the final summary that the user should keep it as a backup until they've confirmed the new repo works, then delete it themselves. Update any desktop/Start shortcuts that pointed at the old `.hta`/`.bat` to the new `dreamstime-tool/` location.

---

## Verification before declaring done (whole-project)

- [ ] MetaGen opens with a legible amber logo, v1.0.0 badge, two platform groups, grouped export dropdown, untested warnings, current model lists with matching prices, and working Save/Load.
- [ ] PS1 fixture smoke test (Task 5.4) passes: dry run + real run + readable embedded metadata + untouched source.
- [ ] HTA opens by double-click, finds its script relatively, remembers settings, shows live progress, and has a working Dry Run.
- [ ] BAT finds its script next to itself and runs; neutral failure text; no "Codex".
- [ ] No file references the old `GPT META gen` path: search the repo for `GPT META gen` → zero matches.
- [ ] Docs render on GitHub; README status table matches `PLATS` tiers; CSV reference matches `PLAT_SPECS`.
- [ ] Report results to the user with evidence (fixture output, screenshots of MetaGen) before claiming completion.
```
