#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
clean_adobe_filenames.py — strip characters Adobe Stock's CSV matcher rejects.

Adobe Stock keeps your uploaded filename exactly as-is, but its bulk-CSV
metadata matcher silently skips any row whose Filename contains square
brackets [ ]. Firefly names files  Firefly_---[Wildlife portrait] ... .jpeg ,
so those images upload with the default "Generated image" title and 0 keywords.

This removes the "[...]" segment from BOTH the image files AND the MetaGen CSV
in a folder, using the identical transform so they still point at each other.
Then you re-upload the renamed files + patched CSV.

Easiest use: drag a folder onto  Clean Adobe filenames.bat .
Command line:
    py clean_adobe_filenames.py "C:\\path\\to\\folder"            # preview only
    py clean_adobe_filenames.py "C:\\path\\to\\folder" --apply    # do it
    py clean_adobe_filenames.py "C:\\path\\to\\folder" --interactive  # preview, ask, do it
"""
import csv, os, re, shutil, sys

# print Thai/Unicode reliably in a Windows cmd window: switch the console to UTF-8
# at runtime (doing it here, not via `chcp` in the .bat, avoids cmd's batch-parse bug).
if sys.platform == 'win32':
    try:
        import ctypes
        ctypes.windll.kernel32.SetConsoleOutputCP(65001)
        ctypes.windll.kernel32.SetConsoleCP(65001)
    except Exception:
        pass
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

IMG_EXT = ('.jpeg', '.jpg', '.png', '.gif', '.tif', '.tiff', '.svg', '.eps', '.mov', '.mp4')

def clean(name):
    # ponytail: only [ ] break Adobe's CSV matcher; commas/spaces/hyphens match fine.
    # Remove the whole "[...]" segment (Firefly's category tag) plus its trailing space.
    return re.sub(r'\s{2,}', ' ', re.sub(r'\[[^\]]*\]\s*', '', name)).strip()

def plan_folder(folder):
    files = [f for f in os.listdir(folder) if f.lower().endswith(IMG_EXT)]
    todo = [(f, clean(f)) for f in files if clean(f) != f]
    existing = set(files)
    seen, safe, blocked = {}, [], []
    for old, new in todo:
        if new in seen or (new in existing and new != old):
            blocked.append((old, new)); continue
        seen[new] = old
        safe.append((old, new))
    csvs = [f for f in os.listdir(folder) if f.lower().endswith('.csv') and not f.lower().endswith('.bak')]
    return files, safe, blocked, csvs

def patch_csv(path, apply):
    with open(path, encoding='utf-8-sig', newline='') as f:
        rows = list(csv.reader(f))
    changed = sum(1 for r in rows[1:] if r and clean(r[0]) != r[0])
    if changed and apply:
        bak = path + '.bak'
        if not os.path.exists(bak):
            shutil.copy2(path, bak)          # keep the very first original
        for r in rows[1:]:
            if r:
                r[0] = clean(r[0])
        with open(path, 'w', encoding='utf-8-sig', newline='') as f:
            csv.writer(f, quoting=csv.QUOTE_MINIMAL, lineterminator='\r\n').writerows(rows)
    return changed

def run(folder, apply):
    files, safe, blocked, csvs = plan_folder(folder)
    for old, new in safe:
        if apply:
            os.rename(os.path.join(folder, old), os.path.join(folder, new))
    for c in csvs:
        n = patch_csv(os.path.join(folder, c), apply)
        print(f'   CSV {c}: {n} แถว{"แก้แล้ว" if apply else "จะถูกแก้"}')
    return safe, blocked

def main():
    argv = sys.argv[1:]
    apply = '--apply' in argv
    interactive = '--interactive' in argv
    paths = [a for a in argv if not a.startswith('--')]
    folder = os.path.abspath(paths[0]) if paths else os.getcwd()

    if not os.path.isdir(folder):
        print(f'❌ ไม่พบโฟลเดอร์: {folder}')
        return

    files, safe, blocked, csvs = plan_folder(folder)
    print(f'\n📁 โฟลเดอร์: {folder}')
    print(f'   รูปทั้งหมด {len(files)} ไฟล์  |  ต้องแก้ชื่อ {len(safe)} ไฟล์  |  ชื่อชนกัน {len(blocked)} ไฟล์\n')

    for old, new in safe[:8]:
        print(f'   {old}\n →  {new}\n')
    if len(safe) > 8:
        print(f'   ... และอีก {len(safe) - 8} ไฟล์\n')
    if blocked:
        print('⚠️  ข้ามไฟล์ที่ชื่อจะชนกัน (แก้เองก่อน):')
        for old, new in blocked:
            print(f'   {old}  ->  {new}')
        print()

    if not safe and not any(patch_csv(os.path.join(folder, c), False) for c in csvs):
        print('✅ โฟลเดอร์นี้สะอาดอยู่แล้ว ไม่มีอะไรต้องแก้')
        return

    if apply:
        do = True
    elif interactive:
        try:
            ans = input('👉 กด Enter เพื่อแก้จริง (หรือพิมพ์ n แล้ว Enter เพื่อยกเลิก): ').strip().lower()
        except EOFError:
            ans = 'n'
        do = ans in ('', 'y', 'yes', 'ใช่')
    else:
        do = False
        print('ℹ️  นี่คือ preview เท่านั้น — ยังไม่แก้ไฟล์จริง')

    if do:
        print('\n⏳ กำลังแก้...')
        run(folder, True)
        print(f'\n✅ เสร็จแล้ว: เปลี่ยนชื่อ {len(safe)} ไฟล์ + แก้ CSV (สำรองไฟล์เดิมเป็น .bak)')
        print('   ต่อไป: อัพรูปที่เปลี่ยนชื่อแล้ว + กด Upload CSV ที่ Adobe')
    elif interactive:
        print('\nยกเลิกแล้ว — ไม่มีอะไรถูกแก้')

if __name__ == '__main__':
    main()
