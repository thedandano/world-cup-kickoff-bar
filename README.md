# World Cup Bar

<div align="center">

  **Live 2026 FIFA World Cup scores in your Mac's menu bar**

  ![macOS](https://img.shields.io/badge/macOS-14.0+-black?style=flat-square&logo=apple)
  ![Swift](https://img.shields.io/badge/Swift-6.0+-orange?style=flat-square&logo=swift)
  ![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-blue?style=flat-square&logo=swift)
  ![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)
  ![Platform](https://img.shields.io/badge/platform-macOS-purple?style=flat-square)

  <a href="https://www.buymeacoffee.com/CagXd3ZFyZ"><img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=☕&slug=CagXd3ZFyZ&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" /></a>

  Live scores · Upcoming fixtures · Kickoff alerts — all from your menu bar. No browser required.

</div>

---

## What is it?

World Cup Bar lives quietly in your Mac's menu bar and keeps you up to date on every match of the 2026 FIFA World Cup. Glance up to see the current score; click for upcoming fixtures and a countdown to the next kickoff. It nudges you with a notification before your team plays — so you never miss the whistle while you're heads-down working.

No browser tab. No Dock clutter. Just a tiny ⚽ that's always there when you want it and invisible when you don't.

## Why you'll like it

- ⚽ **Score at a glance** — the live result sits right in your menu bar
- ⭐ **Follow your teams** — the matches you care about jump to the front
- 📅 **What's next** — upcoming fixtures with venue and your local kickoff time (Today / Tomorrow / weekday)
- 🔔 **Kickoff alerts** — a heads-up 5, 15, 30, or 60 minutes before — or off entirely
- 🪶 **Light and native** — built with Swift, sips battery, no Electron
- ✈️ **Works offline** — the last scores you saw are cached and shown instantly on launch
- 🔒 **Private** — your followed teams and settings never leave your Mac

---

## Install

> **Requires macOS 14 (Sonoma) or later**, and Apple's developer tools (run `xcode-select --install` once if you've never built anything on your Mac).

A one-time-purchase download is on the way. For now it's one command to build your own copy:

**1. Build the app**

```bash
./scripts/build-app.sh
```

This produces **`dist/World Cup Bar.app`** — a normal, double-clickable Mac app.

**2. Move it to Applications**

Drag **`World Cup Bar.app`** from the `dist` folder into your **Applications** folder.

**3. Open it the first time**

Because this is a free build that isn't signed with a paid Apple certificate, macOS plays it safe the first time. **Right-click** the app → **Open** → **Open**. You only do this once.

**4. Look up ⚽**

A soccer ball appears in your menu bar. Click it for scores and fixtures. That's it — you're set.

### Launch it automatically when your Mac starts

So it's always there without thinking about it:

1. Open **System Settings → General → Login Items**
2. Under **"Open at Login"**, click the **+**
3. Pick **World Cup Bar** from your Applications folder

Done — it'll start with your Mac from now on.

---

## Make it yours

Click the ⚽ and open **Settings** to:

- **Follow teams** — pick who gets priority in the menu bar and dropdown
- **Menu bar style** — show team codes (USA) or flag emoji (🇺🇸)
- **Kickoff alerts** — choose your lead time, or turn them off
- **Analytics** — leave on to help improve the app, or switch off anytime

---

## Privacy

No personal data is collected. Your followed teams, preferences, and cached scores stay **on your device**. Optional, anonymous usage stats (app version and basic events only) are handled by [TelemetryDeck](https://telemetrydeck.com) and can be turned off completely in **Settings → Analytics**. Match data comes from [worldcup26.ir](https://worldcup26.ir).

---

## For developers

```bash
swift build      # build
swift test       # run the test suite
swiftlint lint --strict   # lint
```

The codebase is strict MVVM with a `WorldCupBarCore` (pure logic) / `WorldCupBar` (SwiftUI) split. Architecture, conventions, and the folder layout are documented in [`CLAUDE.md`](CLAUDE.md). Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## License

MIT — see [LICENSE](LICENSE).

> **No warranty.** This software is provided as-is; the authors aren't responsible for any issues arising from its use.

---

<div align="center">
  <sub>Built for the 2026 FIFA World Cup · Data from worldcup26.ir · Unaffiliated with FIFA</sub>
</div>
