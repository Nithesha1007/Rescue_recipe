# RescueRecipe End-to-End Demo Script & Presentation Runbook 🎬

This script guides presenters, evaluators, and judges through a complete 3-minute end-to-end demonstration of RescueRecipe.

---

## ⏱️ Quick Summary (3-Minute Flow)

| Time | Action | Key Feature Highlighted |
| :--- | :--- | :--- |
| **0:00 - 0:40** | Speak ingredients & natural expiry | Voice Orb, Speech-to-Text & Gemini Extraction |
| **0:40 - 1:00** | Review & save to kitchen | Natural language date resolution & Priority chips |
| **1:00 - 1:40** | View Rescue-First ranked recipes | Expiry-weighted ranking, badge triggers & substitutions |
| **1:40 - 2:30** | Cook step-by-step hands-free | WakeLock, TTS speech reader & voice command navigation |
| **2:30 - 3:00** | Finish recipe & inspect Impact | Inventory auto-deduction, Rescue Points & weekly chart |

---

## 🎙️ Detailed Step-by-Step Script

### Step 1: Voice Input & AI Extraction
1. Launch the app. Point out the warm, food-inspired theme and the prominent **Voice Orb**.
2. Tap the central microphone orb (or say "Speak your ingredients").
3. Speak clearly into the microphone:
   > **"I have three tomatoes, two onions, spinach and two potatoes. My tomatoes expire tomorrow."**
4. Watch the glowing animated waveform pulse in real time.
5. Tap the orb to finish (or wait for automatic speech detection).
6. **Key Callout**: Notice how Gemini automatically parsed:
   - `Tomatoes`: quantity `3`, unit `pieces`, expiry date resolved to **tomorrow** (marked **High priority** with orange indicator).
   - `Onions`: quantity `2`, unit `pieces`.
   - `Spinach`: unit `bunch` / item.
   - `Potatoes`: quantity `2`, unit `pieces`.
7. Tap **"Add all to My Kitchen"**.

---

### Step 2: My Kitchen Inventory
1. Switch to the **Kitchen** tab.
2. Observe the categorized freshness urgency:
   - Tomatoes appear at the top marked **High Priority** (expires tomorrow).
   - Onions, spinach, and potatoes are grouped by their respective freshness tiers.
3. Show the swipe/popup options on an item: **Edit**, **Mark as used**, **Mark as discarded**, and **Delete**.

---

### Step 3: Rescue-First Recipe Generation
1. Switch to the **Recipes** tab.
2. Tap **"Generate Rescue Recipes"** (or observe the automatic list).
3. **Key Callout**:
   - The #1 recipe ranked on top is **"Quick Fresh Tomato Pasta"** (or tomato-based rescue dish).
   - A distinct highlighted badge states: **"Uses 1 urgent item (tomatoes)"**.
   - Show the substitutions section: If an ingredient is missing (e.g. fresh basil), the app automatically suggests a pantry swap (e.g. dried oregano).
4. Tap on the top recipe to open the **Recipe Details** screen.
5. Review the cook time, difficulty, serving count, and detailed ingredient list.

---

### Step 4: Hands-Free Cooking Mode
1. Tap **"Start cooking"** at the bottom of the recipe details screen.
2. The phone enters **Cooking Mode**:
   - Screen stays awake automatically via `wakelock_plus`.
   - The app's voice assistant reads the first preparation step aloud.
3. Demonstrate hands-free voice commands:
   - Say: **"Next"** $\rightarrow$ Moves to step 2 and reads it aloud.
   - Say: **"Repeat"** $\rightarrow$ Re-reads the current instruction.
   - Say: **"How much tomato?"** $\rightarrow$ Responds: *"You need 3 pieces of tomatoes for this recipe."*
   - Say: **"Go to step 3"** or say **"Next"** until reaching the final step.

---

### Step 5: Finish & Track Impact
1. On the final step, say **"Finish cooking"** (or tap the button).
2. The **Inventory Deduction Sheet** slides up:
   - Presents a checklist of ingredients used in the recipe (e.g. 3 tomatoes, 1 onion).
   - User confirms with one tap.
3. Navigate to the **Insights** tab:
   - **Rescue Score** increases.
   - Daily **Streak** updates.
   - Rescued items count increments.
   - The interactive **Weekly Bar Chart** reflects the newly rescued meal.

---

## 💡 Troubleshooting & Edge Cases

- **Offline Mode**: If the device is in airplane mode or the API key is not configured, RescueRecipe seamlessly activates its offline regex rule parser and displays curated offline rescue recipes with zero disruption.
- **Accidental double-taps**: All confirmation buttons are guarded against rapid multi-taps.
- **Display and Font Scaling**: Supports up to 1.5x font scale and landscape orientation without text clipping or layout overflow.
