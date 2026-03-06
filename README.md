# Bhagvad Gita App

A Flutter app that presents Bhagavad Gita verses in a vertical, reels-style experience with modern UI and practical daily-use features.

## Features
- App opens directly to the feed and resumes from the last-read verse.
- Chapter home screen (still available in codebase) with chapter-wise and overall reading progress.
- Vertical feed with smooth swipe navigation.
- Full-screen horizontal swipe on the feed to open verse details (same as info button).
- Gesture hint text is shown only on the first verse card.
- Chapter/verse picker for direct navigation in feed.
- Chapter/verse picker uses responsive verse chips so labels like `Summary` and `Recap` fit cleanly.
- Language toggle between Sanskrit and English view only.
- Dedicated themed Settings page for app controls.
- Saved verses with persistent storage.
- Reading history persistence (last-read verse and recent verses).
- Reading progress tracking per chapter using exact visited verse IDs, excluding summary/recap rows.
- Notifications with morning and evening verse reminders.
- Android home-screen widget with:
  - `fixed` and `random` modes
  - Tap widget to choose verse in `fixed` mode
  - Tap widget to refresh verse in `random` mode
  - Direct fixed-verse picker inside Settings
  - Widget background follows app light/dark theme
  - Widget verse text stays white across themes for readability
  - Language selection (Sanskrit or English only)
- Verse detail bottom sheet with section order: transliteration -> deep dive -> word meanings -> translation.
- Word-meanings section in verse details (when available in source data).
- Share the current verse as an image.
- Share option from saved/bookmarked verses list.
- Chapter progress entry inside Settings with tappable verse chips to jump directly to feed scroll position.
- Settings opens Bookmarks and Chapter Progress directly as sheets from within Settings.
- Overflow-safe verse card layout for compact screens and larger text scales.
- Long verses no longer truncate with `...`; the verse area now scales down and scrolls when needed.
- Main feed verse area is transparent (no blur card) so background artwork stays visible.
- Theme toggle (`Light` / `Dark`) with persistent preference.
- Background image follows selected theme:
  - Dark: `dark.jpeg`
  - Light: `light.jpeg`
- Dynamic verse-tint overlay on top of selected background.
- Current bundled dataset covers all 18 chapters of the Bhagavad Gita.

## Tech Stack
- Flutter (Dart)
- google_fonts
- flutter_local_notifications
- shared_preferences
- share_plus
- path_provider
- timezone

## Getting Started
1. Install Flutter SDK.
2. From project root, install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

## Update Dependencies
To update packages to latest compatible major versions:
```bash
flutter pub outdated
flutter pub upgrade --major-versions
flutter pub get
```

## Project Structure
- `lib/models/` data models.
- `lib/screens/` chapter home, feed, and settings screens.
- `lib/services/` service layer (notifications, widget bridge, verse repository, reading progress).
- `lib/widgets/` reusable UI components.
- `assets/data/` verse source JSON.
- `assets/images/` theme background images (`dark.jpeg`, `light.jpeg`).

## Notes
- Android notifications require notification permissions (runtime on newer Android versions).
- Morning and evening notifications are scheduled in-app and refreshed when the app initializes.
- Add the home widget first, then tap the widget to choose a verse (fixed mode) or refresh random verse (random mode).
- Widget mode can be changed from `Settings -> Widget mode` (`Fixed`, `Random`).
- Widget language can be changed from `Settings -> Widget language` (`Sanskrit`, `English`).
- App theme can be changed from `Settings -> Light theme` toggle.
- Legacy stored language values like `HI`/`Hindi` are normalized to `English` automatically.
- Home-screen widget support is currently Android only.
- Current data state:
  1. `assets/data/verses.json` contains `715` entries across Chapters `1` to `18`.
  2. It includes:
     - `696` non-summary verse rows
     - `19` summary/recap rows (`verse_number = 0`)
     - `10` grouped/range verse rows (e.g. `"verse_number": "5-6"`)
  3. Canonical Bhagavad Gita structure is `18` chapters and `700` verses; the app dataset also includes summary and grouped rows for reading flow.
  4. It follows app schema: `id`, `chapter`, `verse_number`, `original_script`, `transliteration`, `word_meanings`, `translation_english`, `deep_dive_text`, `background_hex_color`.
  5. `verse_number` accepts both numeric values and range strings (`"x-y"`). The app uses the first numeric value for ordering and chapter progress tracking, while preserving the original label for display in the UI.
  6. Summary/recap rows (`verse_number = 0`) remain visible in the feed, but are excluded from verse progress totals.
- If app data looks stale after JSON changes, run:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

## Planned Next Work
1. Further widget styling improvements (launcher compatibility and adaptive contrast).
2. Settings interaction polish and section-level UX refinement.
3. Add a short 4-step onboarding flow covering welcome, gestures, preferences, and notifications/widget intro.
