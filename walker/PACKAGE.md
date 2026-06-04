# walker — Application Launcher

[Walker](https://github.com/abenz1267/walker) — the Wayland-native application launcher used by Omarchy.

## Package Details

- **Type**: Application launcher
- **Target**: `~/.config/walker`
- **Dependencies**: walker (ships with Omarchy)

## Install

```bash
stowup walker
```

## Key Features

- Custom **`ethereal-rice`** theme: floating rounded card, accent border, large search field, accent-highlighted selection.
- Frosted-glass blur via Hyprland `layerrule = blur on, match:namespace walker` (set in `omarchy/.config/hypr/looknfeel.conf`).
- Prefix providers: `/` providers, `.` files, `:` symbols, `=` calc, `@` websearch, `$` clipboard.
