# Pulse scripts

## `render-screenshots.swift`

Generates the 6 App Store screenshots into `docs/screenshots/` at the iPhone 6.9" size (1290×2796).

```bash
swift scripts/render-screenshots.swift
```

Output files: `1-home.png` through `6-pro.png`.

To localize captions: duplicate the script, change the `Screenshot(caption:subtitle:)` strings, and re-run with a different output folder per language. App Store Connect requires one set per language you ship.

## `inject-tr-translations.py`

Adds Turkish translations to `Pulse/Resources/Localizable.xcstrings`. Idempotent — safe to re-run.

```bash
python3 scripts/inject-tr-translations.py
```

Edit the `TR` dictionary inside the script to add new strings.
