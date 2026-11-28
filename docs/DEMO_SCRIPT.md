# RescueRecipe Presentation & Demonstration Script

**Target Duration**: 3:30 (Can be trimmed to 3:00 or extended to 4:00)

---

## ⏱️ Master Script with Timestamps

| Time | Screen | Action [brackets] | Spoken Words "quotes" | What the Judge Should Notice |
| :--- | :--- | :--- | :--- | :--- |
| **0:00 - 0:25** | Home | [Hold phone showing clean Home screen] | "Every week, households throw away edible food simply because items get pushed to the back of the fridge and forgotten until they spoil. RescueRecipe solves this with a voice-first approach: speak your groceries, let the app prioritize what is expiring soonest, cook hands-free, and track your rescue impact." | Clear problem statement, zero marketing jargon, polished warm theme. |
| **0:25 - 1:10** | Voice Input | [Tap the microphone hero button]<br><br>[Speak clearly into the microphone]<br><br>[Tap the orb to finish processing] | "I'll speak my ingredients and expiry dates naturally in one sentence:"<br><br>"I have three tomatoes, two onions, spinach and two potatoes. My tomatoes expire tomorrow."<br><br>"Gemini extracts the structured data, but our Dart engine calculates the calendar dates and urgency." | The glowing `VoiceOrb` animates smoothly. The transcript populates live. On confirmation, Tomatoes show **High priority** with tomorrow's date; spinach shows quantity not given; potatoes show no date (Unknown). |
| **1:10 - 1:40** | Kitchen | [Tap 'Add all to My Kitchen', switch to Kitchen tab] | "Here in My Kitchen, our items are sorted by urgency. The tomatoes are flagged High because they expire tomorrow. Onions and potatoes are fresh. Notice that the AI extracted the words, but our deterministic Dart logic assigned the priority." | Clean priority chips, freshness indicators, smooth list transitions. No text clipping. |
| **1:40 - 2:15** | Recipes | [Switch to Recipes tab, tap top card to open detail] | "When we generate recipes, RescueRecipe doesn't just match keywords—it ranks them using our Rescue-First formula: 45% expiry coverage, 30% availability, 15% speed, and 10% dietary preference. Notice the top recipe uses our expiring tomatoes, explains exactly why it ranked #1, and provides a smart pantry substitution for dried oregano." | Top recipe highlights *"Uses 1 urgent item (tomatoes)"*. The breakdown shows real weighted calculation. |
| **2:15 - 3:10** | Cooking Mode | [Tap 'Start cooking']<br><br>[Let TTS read step 1, then speak]<br><br>[Speak query]<br><br>[Speak finish] | "Now I'm ready to cook, but my hands are messy. I enter Cooking Mode, which keeps the screen awake and reads instructions aloud:"<br><br>"Next."<br><br>"How much tomato?"<br><br>"Finish." | App reads step 1, immediately mutes when listening, advances on "Next", answers "You need 3 pieces of tomatoes", and triggers deduction sheet on "Finish". |
| **3:10 - 3:40** | Insights | [Confirm deductions, switch to Insights tab] | "After cooking, our inventory automatically updates. In Insights, our Rescue Score increases, our rescue streak stays alive, and our weekly bar chart logs the food rescued from the landfill. Note that scores and money saved are clearly marked as illustrative estimates." | Smooth transition, verified inventory decrement, weekly bar chart updates live. |
| **3:40 - 4:00** | Home / Close | [Return to Home screen] | "RescueRecipe: Speak Your Ingredients. Rescue Your Food. Reduce Food Waste. It works reliably offline, runs on-device, and never guesses on food safety. Thank you." | Crisp, professional finish within the allotted presentation window. |

---

## ✂️ How to Adjust Duration

- **To cut to 3:00**:
  - Skip the "How much tomato?" Q&A query in Cooking Mode (saves 20 seconds).
  - Shorten the opening problem hook to one sentence (saves 10 seconds).
- **To extend to 4:00**:
  - Demonstrate a live voice correction in Voice Input: *"Actually, I don't have onions."* (adds 20 seconds).
  - Show the dark mode switch in Profile & Settings and TalkBack semantic labels (adds 10 seconds).

---

## 🛡️ Backup Plans (If Anything Goes Wrong)

| Failure Mode | Immediate Presenter Action | Spoken Pivot |
| :--- | :--- | :--- |
| **Microphone fails to initialize** | Tap "Type instead" and paste the demo sentence. | "The app supports both voice and fast manual entry for noisy environments." |
| **Speech recognition mishears words** | Tap the editable transcript box and adjust the word. | "We designed the transcript to be fully editable so users are never trapped by background noise." |
| **No internet / Gemini quota error** | Turn on Airplane mode and let offline fallback run. | "RescueRecipe is designed offline-first: our local regex engine and bundled recipes handle food rescue without internet." |
| **Room has loud ambient echo** | Use wired earphones with an inline mic or tap buttons. | "Cooking mode supports both full voice control and one-tap tactile buttons." |

---

## 📋 Presenter Cheat Sheet

### 1. The Demo Sentence
> **"I have three tomatoes, two onions, spinach and two potatoes. My tomatoes expire tomorrow."**

### 2. Voice Commands in Cooking Mode
- **"Next"** / **"Continue"** $\rightarrow$ Advances to next step
- **"Back"** / **"Previous"** $\rightarrow$ Returns to previous step
- **"Repeat"** $\rightarrow$ Re-reads the current instruction
- **"How much [ingredient]?"** $\rightarrow$ Reads exact quantity and unit
- **"Pause"** / **"Resume"** $\rightarrow$ Toggles active listening
- **"Finish"** $\rightarrow$ Opens deduction sheet

### 3. Key Numbers to Remember
- **Priority Tiers**: Critical = 0 days, High = 1–2 days, Medium = 3–5 days, Low = >5 days.
- **Rescue-First Formula**: $0.45 \times \text{Coverage} + 0.30 \times \text{Availability} + 0.15 \times \text{Speed} + 0.10 \times \text{Preference}$.
- **Performance**: 281 automated tests (100% pass rate), 0 analyzer issues, full clean architecture verification.

---

## ⚡ 60-Second Elevator Pitch Version

> "Every year, households throw away edible food because items quietly spoil in the back of the fridge. RescueRecipe solves this by making food rescue voice-first. You speak your groceries—*'I have tomatoes expiring tomorrow, onions, and spinach'*—and our deterministic Dart engine classifies their urgency. 
> 
> Our Rescue-First ranking recommends recipes that rescue your soonest-expiring items first. When you cook, our hands-free cooking assistant reads steps aloud and listens for voice commands so you never touch your screen with messy hands. Once finished, your inventory automatically updates, logging your rescued food and waste reduction. 
> 
> It's reliable, works offline, and keeps your private data strictly on your device. RescueRecipe: Speak Your Ingredients. Rescue Your Food. Reduce Food Waste."
