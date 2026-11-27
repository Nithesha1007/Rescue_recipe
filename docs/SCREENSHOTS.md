# Screenshot & Capture Guide

This shot list defines the recommended screenshots for presentation slides, marketing showcases, and project documentation.

---

## 📸 Capture Procedure

To capture high-resolution, uncompressed PNG screenshots from a connected Android device or emulator:

```bash
# Capture and download directly to computer
adb exec-out screencap -p > docs/images/01-home.png
```

Alternatively, use Android's native hardware shortcut (**Power + Volume Down**), then export the image via Android Studio Device File Explorer (`/sdcard/Pictures/Screenshots/`).

---

## 🖼️ Recommended Shot List

| # | Suggested Filename | Screen & State | Orientation & Theme | What to Highlight | Status |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **01** | `docs/images/01-home.png` | **Home Screen (Clean)** | Portrait, Light | Hero header, glowing `VoiceOrb`, empty or initial streak | *To be captured* |
| **02** | `docs/images/02-voice-recording.png` | **Voice Input (Listening)** | Portrait, Light | Live transcript populating, active soundwave animation | *To be captured* |
| **03** | `docs/images/03-voice-confirmation.png`| **Confirmation Sheet** | Portrait, Light | Extracted ingredients, **High Priority** tomato chip, editable fields | *To be captured* |
| **04** | `docs/images/04-kitchen-inventory.png` | **My Kitchen Tab** | Portrait, Light | Grouped freshness urgency chips, freshness rings | *To be captured* |
| **05** | `docs/images/05-recipes-ranked.png` | **Recipes Feed** | Portrait, Light | Top tomato-first recipe, *"Uses 1 urgent item"* badge | *To be captured* |
| **06** | `docs/images/06-recipe-detail.png` | **Recipe Detail Screen** | Portrait, Light | Rescue score breakdown bars (0.45/0.30/0.15/0.10), substitutions | *To be captured* |
| **07** | `docs/images/07-cooking-mode.png` | **Cooking Mode (Step 1)** | Portrait, Dark | Large step typography, `PulsingMic` audio state, hands-free tips | *To be captured* |
| **08** | `docs/images/08-finish-deduction.png` | **Finish Deduction Sheet** | Portrait, Light | Auto-matched checklist of used pantry items | *To be captured* |
| **09** | `docs/images/09-insights-impact.png` | **Impact & Insights Tab** | Portrait, Light | Rescue Score, Streak counter, Weekly Bar Chart | *To be captured* |
| **10** | `docs/images/10-dark-mode-home.png` | **Home Screen (Dark Theme)** | Portrait, Dark | Deep slate background (`#0E1512`), WCAG 2.1 AA text contrast | *To be captured* |
| **11** | `docs/images/11-tablet-landscape.png` | **Recipes (Landscape)** | Landscape (Tablet), Light | Adaptive navigation rail, multi-column grid layout | *To be captured* |

---

*Note: The images above can be committed to `docs/images/` and linked directly in the root README once captured from a physical device or emulator.*
