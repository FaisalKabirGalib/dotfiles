# raycast — App Launcher

Raycast is the macOS replacement for Walker (this repo's Hyprland app
launcher — see `hyprland/.config/walker/`).

## Package Details

- **Type**: App Launcher
- **Dependencies**: Raycast

## Why there's no stowable config here

Unlike every other package in this repo, Raycast has no plain-text config
file to symlink. Its real settings live in the app's own internal storage.
The only portable artifact Raycast produces is a `.rayconfig` file, made
via its own **Export Settings & Data** command — a GUI-only action with no
CLI equivalent, and the export is encrypted with a passphrase you choose.
Importing on a new machine is the mirror-image manual action (**Import
Settings & Data**).

Source: https://manual.raycast.com/import-export

## Workflow

1. Install Raycast, configure it to taste (hotkeys, extensions, snippets,
   themes).
2. Raycast → **Import & Export** → **Export Settings & Data** → choose
   Settings + Extensions (skip anything you don't want version-controlled,
   e.g. leave out anything account-linked).
3. Save the resulting `.rayconfig` file into this directory (e.g.
   `raycast/raycast-backup.rayconfig`) and commit it.
4. On a new machine, after installing Raycast: **Import & Export** →
   **Import Settings & Data**, point it at the committed `.rayconfig`
   file, enter the same passphrase used at export time.

No `.rayconfig` is committed yet — nothing to store until you've done a
real export with your own settings and passphrase.
