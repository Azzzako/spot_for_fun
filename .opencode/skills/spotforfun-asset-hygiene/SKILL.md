---
name: spotforfun-asset-hygiene
description: Avoid asset-related bugs in spot_for_fun: filenames with spaces, stale pubspec caches, accidentally bundled mockups, oversized images, broken multi-line pubspec paths. Use when adding, renaming, or moving an image/font/asset, when seeing `PathNotFoundException` on an asset, or before running `flutter run` after asset changes. Triggers: "add asset", "new image", "missing login_bg", "asset not found", "background not loaded", "image copy". Do NOT use for non-asset code edits.
---

# spotforfun-asset-hygiene

Asset bugs in this repo surface late (cold rebuild, fresh device install, CI) and are expensive to debug. Most are caused by:

1. Filenames with spaces, accents, or uppercase.
2. Files left in the tracked `assets/` tree that should be local-only references.
3. Stale `AssetManifest.bin` after deletions/renames.
4. Uncompressed, full-resolution images bloating the APK.

## Hard rules

### File naming

- `kebab-case.png` / `snake_case.svg`. Never `"image copy.png"` (real bug we hit this session).
- Lowercase only. No spaces, no accents (`café.png` → `cafe.png`).
- `.png` for raster, `.webp` when possible (smaller, transparent support).
- Font files: lowercase + descriptors (`roboto_regular.ttf`).

### Asset directory layout

```
assets/
  identity/      → brand-only assets, declared in pubspec, bundled into app
    logo.png
    background.png
  sample_spots/  → seeded spot photos for dev/demo, declared in pubspec
    skate_01.jpg ...
  ref/           → LOCAL REFERENCES ONLY (mockups, comps, source PNGs)
  untracked/     → dumps, experiments, never commit
```

- `identity/` and `sample_spots/` are the only directories declared in `pubspec.yaml`.
- `ref/` must be listed in `.gitignore` (`assets/ref/`).
- `untracked/` (if created) must be added to `.gitignore`.

### `.gitignore`

Current `spot_for_fun/.gitignore` already lists `assets/ref/` (re-add if a teammate removes it). Verify before any asset-related commit:

```bash
git check-ignore assets/ref/image.png && echo "OK ignored" \
  || echo "BUG: assets/ref not ignored"
```

If the check fails, add the line back to `.gitignore` in the same commit.

### `pubspec.yaml`

Currently declares:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/sample_spots/
    - assets/identity/
```

Rules:

- Use **directory paths**, not glob `*`, unless intentionally bundling a subset.
- Never list individual files unless you're optimizing APK size by excluding specific assets (rare).
- After editing pubspec, run `flutter pub get` and immediately verify with `flutter run --debug` — `AssetManifest.bin` regenerates inside `build/app/intermediates/flutter/<mode>/flutter_assets/assets/`.

### Image compression

For brand assets:

- Logo: ≤ 200 KB, max 1024 px on the long edge, `.webp` if the visual is flat.
- Background: ≤ 1.5 MB, max 2048 px on the long edge, JPEG-q90 is fine if no alpha, otherwise `.webp`.

Run on a Linux box:

```bash
cwebp -q 80 -resize 1024 1024 assets/identity/logo.png -o assets/identity/logo.webp
# or
convert assets/identity/background.png -resize 2048x2048\> -quality 85 background.jpg
```

For Flutter, list `.webp` first in pubspec and keep `.png` as fallback only if some target build needs PNG.

## Recovery protocol — `PathNotFoundException` after asset changes

If `flutter run` fails with:

```
PathNotFoundException: Cannot open file, path = '.../build/.../assets/<x>.png'
```

Cause: stale build cache references a deleted/moved file.

Fix:

```bash
cd /home/azako/proyectos/spot_for_fun
flutter clean
flutter pub get
flutter run            # cold rebuild; AssetManifest regenerates
```

Do NOT disable asset bundling to "fix" this. Do NOT rename the file back to match the cache.

## Pre-commit checklist for any asset change

```bash
# 1. file names clean
ls assets/identity/ assets/sample_spots/ assets/ref/ 2>/dev/null \
  | grep -E ' |[^a-z0-9_./-]' && echo "BAD: bad filename" || echo "OK names"

# 2. ref/ ignored
git check-ignore assets/ref/* 2>/dev/null

# 3. no accidental mockups staged
git status --short | grep -E 'untracked|\?\? assets/ref' \
  && echo "Review: ref/ files untracked — intentional?"

# 4. pubspec in sync
flutter pub get

# 5. analyze + test
dart analyze
flutter test
```

If any step fails, fix before `git add`.

## When adding a new asset

1. Create at the right path (`assets/<category>/<kebab-name>.<ext>`).
2. If new category, add its directory to `pubspec.yaml` under `flutter.assets:`.
3. `flutter pub get`.
4. Reference via `Image.asset('assets/<category>/<name>.<ext>')` (no leading `/`).
5. If the file is a **reference / mockup** (not for the app), put it under `assets/ref/`. Do NOT add `assets/ref/` to pubspec.
6. `flutter run` to verify. Hot-restart is enough; full clean only needed after deletes/renames.

## When removing an asset

1. `git rm assets/<...>` (or plain `rm` if never tracked).
2. If the asset was the only file keeping a category alive, remove that category from `pubspec.yaml`.
3. `flutter pub get && flutter clean && flutter pub get`.
4. Verify `AssetManifest.bin` regenerated: `unzip -p build/.../flutter_assets/assets/flutter_assets/AssetManifest.json | head`.

## Anti-patterns observed in this repo

- `assets/identity/image copy.png` (provisional mockup left in tree, untracked, has space).
- `assets/ref/image.png` (correctly in `.gitignore`, correctly not in pubspec, correctly untracked).
- The `PathNotFoundException: .../login_bg.png` runtime bug we hit this session — fixed by `flutter clean`. Don't let it recur.

## Reference files

- `pubspec.yaml` lines 38–43 — current asset declarations.
- `.gitignore` line 53+ — current ignore rules.
- `lib/ui/features/auth/views/login_screen.dart` — first use of `assets/identity/background.png` and `logo.png`.
