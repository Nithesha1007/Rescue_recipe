# RescueRecipe

> Speak Your Ingredients. Rescue Your Food. Reduce Food Waste.

Household food waste is an enormous economic and environmental problem. In everyday life, ingredients perish quietly in the refrigerator because people forget what they bought, overlook expiration dates, or lack the energy to figure out how to combine odd leftovers into a cohesive meal. 

RescueRecipe tackles this problem with a voice-first approach: speak your groceries and natural expiry dates into your phone, let the system prioritize items about to spoil, discover Rescue-First recipes that prioritize those items, and follow hands-free voice-guided cooking without having to touch your phone with food-covered hands.

---

## Core Flow

```text
[ Speak ] ──> [ Identify ] ──> [ Prioritize ] ──> [ Recommend ] ──> [ Cook ] ──> [ Track ]
```

1. **Speak**: User speaks raw ingredients and natural expiration phrases in one sentence.
2. **Identify**: Gemini or the offline rule-based parser extracts names, quantities, and units.
3. **Prioritize**: Dart resolves dates, calculates remaining days, and classifies urgency tiers.
4. **Recommend**: Rescue-First ranking evaluates coverage, availability, and speed, placing the top rescue meal first.
5. **Cook**: Voice assistant reads instructions aloud and listens for hands-free commands.
6. **Track**: Confirmed deductions decrement inventory, incrementing Rescue Points, streaks, and waste metrics.

---

## Features

- **Voice Input with Live Feedback**: Speech-to-text with glowing animated `VoiceOrb` waveform.
- **Editable Transcript & Corrections**: Full text editing and conversational voice corrections (*"Actually I don't have onions"*).
- **Offline Fallback Parser**: Fast regex-based parser extracts quantities, units, and dates when offline or without an API key.
- **Expiry Priority Engine**: Dynamic classification into 6 urgency tiers based on calendar days left.
- **Urgent Expiry Notifications**: Local notifications planned for critical and high-priority items.
- **Rescue-First Recipe Generation**: AI-generated recipes filtered and ranked deterministically by Dart.
- **Transparent Match Reason & Badges**: Explains why a recipe ranked high (e.g. *"Uses 1 urgent item (tomatoes)"*).
- **Substitutions for Missing Items**: Suggests realistic pantry swaps for missing ingredients.
- **Hands-Free Cooking Mode**: Text-to-speech reads steps aloud while on-device parser responds to voice navigation (*"Next"*, *"Repeat"*, *"How much onion?"*).
- **Screen WakeLock**: Prevents screen sleep while actively cooking.
- **Kitchen Inventory**: Hive-backed offline pantry with freshness rings and status management.
- **Impact & Insights**: Illustrative gamified metrics:
  - *Rescue Score* (illustrative point score)
  - *Rescue Streak* (illustrative consecutive rescue tracking)
  - *Estimated Money Saved* (illustrative financial savings estimate)
  - *Achievements* (illustrative milestone badges)
- **Profile & Preferences**: Dietary rules (Vegetarian, Vegan, Gluten-Free, Keto, etc.), speech speed controls, appearance toggle, and complete local data reset.

---

## What the AI Does vs What Dart Does

| Responsibility | Handled By | Implementation Details |
| :--- | :--- | :--- |
| **Extract ingredients from speech** | **Gemini AI** | Extracts names, quantities, units, and raw expiry phrases into structured JSON. |
| **Generate recipes & steps** | **Gemini AI** | Generates title, minutes, ingredients, steps, and substitution suggestions. |
| **Calculate dates from phrases** | **Dart (Pure)** | Resolves phrases like *"tomorrow"*, *"friday"*, *"in 3 days"* into exact calendar `DateTime`. |
| **Determine expiry priority** | **Dart (Pure)** | Compares target date against today's date into mathematical day differences. |
| **Rank recipes (Rescue-First)** | **Dart (Pure)** | Mathematical weighted formula balancing coverage, availability, speed, and diet. |
| **Validate match reasons** | **Dart (Pure)** | Validates or replaces AI reason strings with strictly verified inventory facts. |
| **Voice command parsing** | **Dart (Pure)** | On-device regex matching for navigation (*"Next"*, *"Back"*, *"Repeat"*, *"Finish"*). |
| **Inventory & deductions** | **Dart (Pure)** | Local Hive CRUD, deduplication merging, and post-cooking inventory updates. |
| **Safety evaluation** | **Neither** | **Neither Dart nor Gemini guarantees food safety.** Expiry dates are purely estimates. |

---

## Key Rules & Formulas

### Expiry Priority by Calendar Days Left

| Days Left | Priority Tier | Color Role | Description |
| :--- | :--- | :--- | :--- |
| **< 0** | **Expired** | Burgundy (`#7B1111`) | Past expiry date. Excluded from recipe generation. |
| **0** | **Critical** | Red (`#D32F2F`) | Expires today. Highest rescue urgency. |
| **1 to 2** | **High** | Orange (`#E86A33`) | Expires tomorrow or day after. Primary rescue target. |
| **3 to 5** | **Medium** | Amber (`#FFC107`) | Approaching expiry within the week. |
| **> 5** | **Low** | Forest Green (`#2E7D32`) | Fresh; plenty of shelf life remaining. |
| *null* | **Unknown** | Slate Grey (`#616161`) | No date provided; preserved as staple/unknown. |

### Rescue-First Ranking Formula

$$\text{Score} = 0.45 \times \text{Coverage} + 0.30 \times \text{Availability} + 0.15 \times \text{Speed} + 0.10 \times \text{Preference}$$

- **Coverage ($0.45$)**: Weighted sum of used expiring ingredients (Critical = 3, High = 2, Medium = 1) divided by total expiring weight in inventory.
- **Availability ($0.30$)**: Ratio of required non-staple ingredients available in inventory to total required non-staple recipe ingredients. Recipes with availability $< 0.4$ are excluded.
- **Speed ($0.15$)**: Scaled cook time: $\text{clamp}(1.0 - \frac{\text{minutes} - 10}{50.0}, 0.0, 1.0)$.
- **Preference ($0.10$)**: $1.0$ if matching active dietary preference, $0.5$ if no preference set. Recipes conflicting with an active diet are excluded entirely.

---

## Reliability & Offline Design

1. **Editable Transcript**: The user always inspects and can edit speech recognition transcripts before sending.
2. **Offline Fallback Extraction**: If Gemini is unreachable or no API key is provided, the local parser extracts ingredients using regex rules.
3. **Bundled Offline Recipes**: 3 curated fallback recipes (Stir-Fry, Frittata, Fried Rice) ensure recipe generation succeeds offline.
4. **Network Resilience**: Gemini remote calls feature a 20-second timeout with an automatic single retry before falling back to offline sources.
5. **Mic Permission Handling**: Rejection prompts an informative banner with an immediate button to open system app settings.
6. **Permanent Food Safety Disclaimer**: Every screen with food data displays an explicit disclaimer reminding users to use sensory judgment.

---

## Tech Stack & Dependencies

Extracted directly from [pubspec.yaml](file:///c:/Users/nithe/rescue_recipe/pubspec.yaml):

| Package | Version | Purpose |
| :--- | :--- | :--- |
| **flutter_bloc** | `^9.1.0` | Predictable state management |
| **equatable** | `^2.0.7` | Value equality for state comparisons |
| **get_it** | `^8.0.3` | Service locator / Dependency injection |
| **fpdart** | `^1.1.1` | Functional programming & `Either<Failure, T>` |
| **hive** / **hive_flutter** | `^2.2.3` / `^1.1.0` | Fast, lightweight local NoSQL storage |
| **http** | `^1.3.0` | REST API communication with Google Gemini |
| **speech_to_text** | `^7.0.0` | On-device speech recognition |
| **flutter_tts** | `^4.2.2` | Text-to-speech audio reader |
| **wakelock_plus** | `^1.2.8` | Screen wake-lock during active cooking |
| **connectivity_plus** | `^6.1.3` | Network status monitoring |
| **permission_handler** | `^11.4.0` | Runtime Android microphone and notification permissions |
| **flutter_local_notifications** | `^18.0.1` | Device notification scheduling |
| **timezone** / **flutter_timezone**| `^0.10.0` / `^3.0.1`| Accurate timezone scheduling for expiry alerts |

---

## Setup & Running

### Prerequisites
- **Flutter SDK**: `3.27.0+` (Developed and verified on Flutter 3.38.x / Dart 3.6.x)
- **Android SDK**: API 34+ (Target SDK 34, Min SDK 21)

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Configure Environment Keys
Copy `env.example.json` to `env.json`:
```bash
cp env.example.json env.json
```
Edit `env.json` and insert your Gemini API key from [Google AI Studio](https://aistudio.google.com/):
```json
{
  "GEMINI_API_KEY": "AIzaSy..."
}
```

> **API Key Security Note**: `env.json` is ignored by `.gitignore` and never committed. Note that any API key compiled directly into a client mobile binary can theoretically be extracted by reverse engineering. For a production app, client calls should route through a secure backend proxy.

### Step 3: Run the App
```bash
# With Gemini API enabled
flutter run --dart-define-from-file=env.json

# In fully offline mode (no key needed)
flutter run
```

### Step 4: Build & Install Release APK
```bash
# Build release APK
flutter build apk --release

# Install onto connected phone via adb
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Release APK Output size: **53.9 MB** (verified).

---

## Testing

RescueRecipe features a comprehensive test suite of **195 automated tests** across data, domain, presentation, accessibility, and quality guards:

```bash
flutter test
```

### Test Suite Structure
- `test/features/cooking/`: Command parsing, audio session controllers, inventory deductions, quantity answering.
- `test/features/ingredients/`: Date resolution, day calculation, merging logic, inventory cubit.
- `test/features/insights/`: Score and streak calculation, weekly chart aggregation, insights cubit.
- `test/features/recipes/`: Gemini parsing, fallback sources, matcher, reason validator, ranker logic.
- `test/features/voice/`: Transcript extraction, correction logic, voice bloc, UI state tests.
- `test/quality/forbidden_patterns_test.dart`: Asserts 0 `print()` calls, 0 raw colors, 0 raw font sizes, 0 placeholders, and 0 hardcoded keys.
- `test/theme/theme_contrast_test.dart`: Calculates WCAG 2.1 relative luminance and contrast ratios ($\ge 4.5:1$).
- `test/responsive/responsive_matrix_test.dart`: Renders all core screens across 6 screen configurations and 1.5x font scale.

---

## Project Structure

```
lib/
├── app.dart                                # MaterialApp configuration & routing
├── main.dart                               # App entry point, error traps & DI init
├── core/
│   ├── config/app_config.dart              # Dart define environment parser
│   ├── constants/app_strings.dart          # String resources
│   ├── di/injection.dart                   # GetIt service registrations
│   ├── domain/expiry_priority.dart         # Pure Dart priority enum & day math
│   ├── error/failures.dart                 # Functional failures hierarchy
│   ├── theme/app_theme.dart                # Colors, tokens, ThemeExtensions, typography
│   ├── usecase/usecase.dart                # Generic base UseCase contract
│   ├── utils/                              # Haptics, AppLogger, responsive builders
│   └── widgets/                            # Reusable widgets (cards, buttons, chips, orbs)
└── features/
    ├── cooking/                            # Cooking session, voice commands & TTS
    ├── ingredients/                        # Inventory management & date resolver
    ├── insights/                           # Rescue points, streaks & waste statistics
    ├── notifications/                      # Local alert planning & scheduling
    ├── recipes/                            # Gemini generation & Rescue-First ranking
    ├── settings/                           # User preferences & data management
    ├── shell/                              # Navigation shell & Home dashboard
    └── voice/                              # Audio recording & ingredient extraction
```

---

## Known Limitations

- **Speech Recognition Hardware Dependency**: Recognition accuracy depends on device microphones and Google Speech Services.
- **English Language Only**: Natural language date phrases and voice commands are currently modeled in English.
- **Estimated Savings**: Monetary savings calculations use fixed average grocery cost approximations ($2.50/item) and are illustrative estimates.
- **Battery Optimization on Notifications**: Extreme power-saver modes on OEM devices (e.g. Xiaomi, Samsung) may delay scheduled local notifications.
- **AI Hallucinations**: Recipe generation is generative; instructions and substitutions require user common sense.
- **Platform Scope**: Tested and compiled specifically for Android mobile devices.

---

## Food Safety & Privacy Policy

- **Approximate Dates**: Expiry dates and priority tiers are approximations. Users must always check smell, appearance, and texture before consumption. Spoiled food must be discarded.
- **Device-Only Data Storage**: Kitchen inventory, preferences, and cooking history are stored exclusively in local Hive boxes on the device.
- **Minimal Cloud Exposure**: When using online AI features, only raw transcript text and active ingredient names/quantities are transmitted to the Gemini API. Expiration dates, user identity, and location are never transmitted.

---

## Roadmap

1. **Barcode & Receipt Scanning**: Direct photo ingestion of grocery store receipts using on-device ML Kit.
2. **Smart Refrigerator Sync**: Integration with smart home APIs to automatically reflect purchased groceries.
3. **Multi-Language Voice Support**: Expanding voice parsing and cooking commands to Spanish, French, and Hindi.
4. **Cloud Backup & Family Sharing**: Optional end-to-end encrypted pantry synchronization between household members.
