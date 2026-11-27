# RescueRecipe: Phase 1

## Create the project and drop these files in

```bash
flutter create --org com.rescuerecipe --project-name rescue_recipe --platforms android rescue_recipe
```

Copy this folder's `lib/`, `test/`, `pubspec.yaml`, `analysis_options.yaml` and `env.example.json`
over the new project (replace when asked). Delete `test/widget_test.dart` from the template first
if your copy tool does not overwrite. Append `gitignore_additions.txt` to `.gitignore`.

## Run

```bash
cp env.example.json env.json        # put your real Gemini key in env.json (git-ignored)
flutter pub get
flutter run --dart-define-from-file=env.json
flutter test
flutter analyze
```

Phase 1 does not call Gemini yet; the key is only read into `AppConfig`.

## Verification checklist

- [ ] `flutter pub get` succeeds
- [ ] `flutter analyze` shows no issues
- [ ] `flutter test` passes (5 tests)
- [ ] App opens on Home: gradient header, voice orb animating, "Speak your ingredients" button
- [ ] Tapping the button shows a "Phase 3" snackbar and gives haptic feedback
- [ ] Bottom bar shows Home, Kitchen, Recipes, Insights, Profile; tabs switch
- [ ] Design preview shows all six priority chips, four ingredient tiles with freshness rings, two recipe cards, three stat tiles
- [ ] Expiry disclaimer visible on every tab
- [ ] Rotate to landscape: no overflow, scrolls
- [ ] Rotate tablet or resize to over 600dp: navigation rail replaces bottom bar
- [ ] Set system font size to the largest: no overflow
- [ ] Toggle system dark mode: all text readable, ring and chip colors still clear
- [ ] `env.json` does not appear in `git status`
