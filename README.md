# Bhagvad Gita App

A Flutter app that presents Bhagavad Gita verses in a vertical, reels-style experience with modern UI and practical daily-use features.

## Features
- Chapter home screen with chapter-wise and overall reading progress.
- Vertical feed with smooth swipe navigation.
- Search and jump to verses by chapter/verse, verse ID, Sanskrit, transliteration, or English text.
- Chapter/verse segmented search picker for direct navigation.
- Language toggle between Sanskrit and English view only.
- Dedicated themed Settings page for app controls.
- Saved verses with persistent storage.
- Reading history persistence (last-read verse and recent verses).
- Reading progress tracking per chapter.
- Daily notifications with two entries:
  - Today's Verse
  - Random Verse
- Android home-screen widget with:
  - User-selected verse
  - Language selection (Sanskrit or English only)
- Verse detail bottom sheet with transliteration, translation, and deep-dive text.
- Word-meanings section in verse details (when available in source data).
- Share the current verse as an image.
- Share option from saved/bookmarked verses list.
- Chapter progress entry inside Settings with tappable verse chips to jump directly to feed scroll position.
- Dynamic gradient backgrounds based on verse metadata.
- Custom curated starter dataset (50 verses) in app format, ready for incremental expansion.

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
- `tools/generate_custom_50_verses.ps1` helper script for generating starter custom dataset.

## Notes
- Android notifications require notification permissions (runtime on newer Android versions).
- Daily notifications are scheduled in-app and refreshed when the app initializes.
- Add the home widget from Android widget picker, then open `Settings -> Choose widget verse` to pin a specific verse.
- Widget language can be changed from `Settings -> Widget language` (`Sanskrit`, `English`).
- Legacy stored language values like `HI`/`Hindi` are normalized to `English` automatically.
- Home-screen widget support is currently Android only.
- Current custom data state:
  1. `assets/data/verses.json` contains custom 50 verses (`BG_01_01` to `BG_02_03`)
  2. It follows app-ready schema: `id`, `chapter`, `verse_number`, `original_script`, `transliteration`, `word_meanings`, `translation_english`, `deep_dive_text`, `background_hex_color`
- To regenerate the current starter set:
  ```bash
  powershell -ExecutionPolicy Bypass -File tools/generate_custom_50_verses.ps1
  ```
