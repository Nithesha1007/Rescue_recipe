# Judge Q&A & Technical Defense Guide

This guide prepares the presenter for rigorous technical, architectural, and ethical questions from judges.

---

### 1. Why does Dart do the ranking instead of the AI?
**Answer**: Determinism, speed, and safety. If an LLM ranks recipes, ranking becomes a non-deterministic black box prone to hallucinations and slow network roundtrips. In RescueRecipe, our pure Dart engine deterministically computes a weighted mathematical formula ($0.45 \times \text{coverage} + 0.30 \times \text{availability} + 0.15 \times \text{speed} + 0.10 \times \text{preference}$) in under 2 milliseconds on-device. This guarantees that recipes with urgent, expiring ingredients rank on top every single time without latency.

---

### 2. How do you prevent the AI from claiming food is safe to eat?
**Answer**: Two-layer defense:
1. **Prompt Isolation**: Gemini is strictly constrained to extract ingredient names and quantities, and to generate culinary steps. The system prompt explicitly forbids generating safety guarantees, spoilage assessments, or shelf-life predictions.
2. **Permanent UI Disclaimer**: Every screen rendering food or expiry data includes an `ExpiryDisclaimer` widget emphasizing that all dates are estimates and that users must inspect smell, texture, and appearance.

---

### 3. How are dates handled when the user says "tomorrow" or "friday"?
**Answer**: Gemini extracts the raw text phrase (e.g. `"tomorrow"` or `"friday"`). Then, our pure Dart `ExpiryDateResolver` strips time components, checks the current device calendar day, and maps the relative phrase into an exact calendar `DateTime`. Gemini never performs calendar arithmetic.

---

### 4. What happens when the device is completely offline?
**Answer**: The app gracefully degrades with zero crashes:
1. **Extraction**: An on-device regex rule parser (`OfflineIngredientParser`) extracts numbers, common culinary units, and relative date keywords.
2. **Recipes**: The app falls back to three curated offline rescue recipes (Frittata, Stir-Fry, Fried Rice) designed to absorb arbitrary expiring ingredients.
3. **Cooking**: Voice commands and TTS operate 100% on-device without network calls.

---

### 5. What happens if Gemini returns malformed or invalid JSON?
**Answer**: All HTTP responses pass through `GeminiRemoteDataSource` which enforces a 20-second timeout, retries once on transient failure, and wraps deserialization in try-catch blocks. If parsing fails, the data layer returns a `ServerFailure` within an `Either.left`, triggering an automatic fallback to the offline parser without throwing unhandled exceptions.

---

### 6. How are duplicate ingredients handled when adding new items?
**Answer**: `IngredientMerger` inspects existing pantry items. If an incoming item matches an existing active ingredient name:
- Quantities are summed if the units match.
- The earliest expiry date is preserved to ensure the urgency indicator reflects the soonest-expiring batch.

---

### 7. How do voice corrections work?
**Answer**: Users can either edit the text field directly before confirmation or speak a correction phrase such as *"Actually I don't have onions"*. The `ApplyVoiceCorrection` use case uses pattern matching for negation terms (*"no"*, *"don't have"*, *"remove"*, *"delete"*) to prune the item from the pending list.

---

### 8. Why use Hive instead of SQLite or Room?
**Answer**: Hive is a lightweight, pure Dart NoSQL key-value store with zero native dependencies. For local-only mobile caching of ingredient lists and usage history, Hive provides sub-millisecond read/write speeds, avoids complex SQL migrations, and requires no platform channel overhead.

---

### 9. Why use Bloc and Cubit for state management?
**Answer**: We use `Bloc` for complex asynchronous event streams with multiple event types (such as `VoiceInputBloc` handling live audio streams and `CookingBloc` managing speech mutual exclusion), and `Cubit` for simpler state stores (such as `InventoryCubit`, `SettingsCubit`, and `NavigationCubit`). This separation provides testable, unidirectional data flow with zero UI business logic.

---

### 10. How do you guarantee the app never speaks and listens at the same time?
**Answer**: In `VoiceSessionController`, Text-To-Speech (`flutter_tts`) and Speech-To-Text (`speech_to_text`) are mutually exclusive. Before TTS speaks, STT is explicitly stopped and audio input is torn down. Only when the TTS `setCompletionHandler` callback fires is the microphone re-initialized to listen for user commands.

---

### 11. What are your privacy practices? Does my pantry data leave my phone?
**Answer**: No. All pantry inventory, cooking logs, streaks, and preferences stay on the physical device in encrypted Hive boxes. When online AI features are used, only the spoken transcript and active ingredient names/quantities are sent to Gemini. Expiration dates, user identity, and location are never transmitted.

---

### 12. How is the Gemini API key secured?
**Answer**: The API key is injected at compile time via `--dart-define-from-file=env.json`. The `env.json` file is explicitly ignored in `.gitignore` to prevent repository leaks. In our documentation, we openly disclose that client-side keys in production should be proxied through a secure backend server.

---

### 13. How did you verify accessibility (WCAG AA)?
**Answer**:
1. **Contrast**: An automated test (`test/theme/theme_contrast_test.dart`) mathematically calculates WCAG 2.1 relative luminance for all theme text and surface pairs, verifying all exceed the 4.5:1 AA threshold.
2. **Touch Targets**: All buttons, chips, and tiles adhere to the $\ge 48 \times 48\,\text{dp}$ touch target guideline.
3. **Reduced Motion**: All ambient animations (`VoiceOrb`, `PulsingMic`) inspect `MediaQuery.disableAnimationsOf(context)` and halt when reduced motion is enabled.

---

### 14. How is "Estimated Money Saved" calculated and why is it labeled estimated?
**Answer**: `InsightsCalculator` multiplies rescued ingredients by an average grocery replacement value of $2.50 per rescued item. Because food prices fluctuate widely by region and brand, this metric is clearly labeled as an illustrative estimate rather than an exact accounting guarantee.

---

### 15. What was the hardest bug encountered during development?
**Answer**: Resolving audio session contention between `speech_to_text` and `flutter_tts` on Android. Initial prototypes suffered from audio channel locking where starting STT immediately after TTS caused Android's `AudioRecord` to fail with error code 1. We solved this by implementing an explicit state machine with lifecycle-aware cleanup and a debounce buffer between completion events.

---

### 16. What would you build next?
**Answer**: Receipt and barcode scanning using on-device ML Kit, and multi-language support (Spanish and French) for both date phrase parsing and cooking voice commands.
