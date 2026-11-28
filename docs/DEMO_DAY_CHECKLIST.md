# Demo Day Preparation Checklist

Ensure every item is verified before presenting or recording RescueRecipe.

---

## 🌙 Night Before Checklist

- [ ] **Release APK Installed**: Build the latest release APK using `flutter build apk --release` and install via `adb install -r build/app/outputs/flutter-apk/app-release.apk`.
- [ ] **Android System Services**: Update "Google" and "Speech Services by Google" from the Google Play Store on the demo phone.
- [ ] **Hardware Permissions Granted**:
  - Open App Info $\rightarrow$ Permissions $\rightarrow$ Enable **Microphone**.
  - Enable **Notifications**.
- [ ] **Power & Display Settings**:
  - Turn **Battery Saver OFF** and exclude RescueRecipe from background power restrictions.
  - Set Screen Timeout to **10 minutes** or **Never**.
  - Set Screen Brightness to ~80% (consistent for presentation visibility).
- [ ] **Audio & Network**:
  - Volume up (Media volume set to 75%+).
  - Verify Wi-Fi connectivity and run a test query to confirm Gemini API key quota is active.
- [ ] **Airplane Mode Dry Run**:
  - Turn on Airplane mode on the device and perform a test extraction and recipe generation to confirm offline fallback parsers work.
- [ ] **Backup Assets**:
  - Copy a backup APK to a USB drive or secondary Android device.
  - Record a backup 3-minute screen capture video of a clean run-through.
- [ ] **Physical Script**: Print or save an offline PDF of [DEMO_SCRIPT.md](file:///c:/Users/nithe/rescue_recipe/docs/DEMO_SCRIPT.md).

---

## ⏰ 1 Hour Before Checklist

- [ ] **Do Not Disturb**: Enable **Do Not Disturb** (block calls, messages, and social media notifications during the presentation).
- [ ] **Screen Mirroring**: Test screen casting via HDMI cable, scrcpy (`scrcpy -m 1920 -b 8M`), or wireless display adapter.
- [ ] **Room Acoustics**:
  - Test speaking into the microphone from arm's length in the presentation room.
  - If room has heavy audio echo or high ambient noise, connect a low-profile wired lapel mic or headset.
- [ ] **TTS Speech Speed**:
  - In Profile & Settings, test TTS speed (1.0x recommended).
- [ ] **Device State Reset**: Follow the reset procedure below to start from a clean state.

---

## 🔄 Reset Between Demo Runs

To reset the app to an pristine state in under 10 seconds:

1. Open RescueRecipe.
2. Tap the **Profile / Settings** tab (far right).
3. Scroll down to **Data & Privacy**.
4. Tap **"Clear All My Data"** $\rightarrow$ Confirm **"Clear All Data?"**.
   - *Result*: Clears all ingredients from Hive, resets preferences, and clears usage history.
5. Return to the **Home** screen.
   - *Result*: Clean initial dashboard ready for the demo speech sentence.
