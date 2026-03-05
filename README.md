# Bhagvad Gita App

A Flutter app that presents Bhagavad Gita verses in a vertical, reels-style experience with modern UI and practical daily-use features.

## Features
- App opens directly to the feed and resumes from the last-read verse.
- Chapter home screen (still available in codebase) with chapter-wise and overall reading progress.
- Vertical feed with smooth swipe navigation.
- Full-screen horizontal swipe on the feed to open verse details (same as info button).
- Gesture hint text is shown only on the first verse card.
- Search and jump to verses by chapter/verse, verse ID, Sanskrit, transliteration, or English text.
- Chapter/verse segmented search picker for direct navigation.
- Language toggle between Sanskrit and English view only.
- Dedicated themed Settings page for app controls.
- Saved verses with persistent storage.
- Reading history persistence (last-read verse and recent verses).
- Reading progress tracking per chapter using exact visited verse IDs.
- Daily notifications with a single daily verse reminder.
- Android home-screen widget with:
  - `fixed` and `random` modes
  - Tap widget to choose verse in `fixed` mode
  - Tap widget to refresh verse in `random` mode
  - Language selection (Sanskrit or English only)
- Verse detail bottom sheet with section order: transliteration -> deep dive -> word meanings -> translation.
- Word-meanings section in verse details (when available in source data).
- Share the current verse as an image.
- Share option from saved/bookmarked verses list.
- Chapter progress entry inside Settings with tappable verse chips to jump directly to feed scroll position.
- Settings actions return to feed and then open their target sheet (Bookmarks/Chapter Progress).
- Overflow-safe verse card layout for compact screens and larger text scales.
- Main feed verse area is transparent (no blur card) so background artwork stays visible.
- Theme toggle (`Light` / `Dark`) with persistent preference.
- Background image set rotates on app start within selected theme:
  - Dark: `dark.jpeg`, `dark (2).jpeg`
  - Light: `light.jpeg`, `light (2).jpeg`
- Dynamic verse-tint overlay on top of selected background.
- Current bundled dataset through Chapter 17 (currently up to 17.8).

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
- `assets/images/` theme background images (`dark*`, `light*`).

## Notes
- Android notifications require notification permissions (runtime on newer Android versions).
- Daily notifications are scheduled in-app and refreshed when the app initializes.
- Add the home widget first, then tap the widget to choose a verse (fixed mode) or refresh random verse (random mode).
- Widget mode can be changed from `Settings -> Widget mode` (`Fixed`, `Random`).
- Widget language can be changed from `Settings -> Widget language` (`Sanskrit`, `English`).
- App theme can be changed from `Settings -> Light theme` toggle.
- Legacy stored language values like `HI`/`Hindi` are normalized to `English` automatically.
- Home-screen widget support is currently Android only.
- Current data state:
  1. `assets/data/verses.json` contains `622` entries across Chapters `1` to `17`.
  2. It includes:
     - `604` non-summary verse rows
     - `18` summary/recap rows (`verse_number = 0`)
     - `9` grouped/range verse rows (e.g. `"verse_number": "5-6"`)
  3. It follows app schema: `id`, `chapter`, `verse_number`, `original_script`, `transliteration`, `word_meanings`, `translation_english`, `deep_dive_text`, `background_hex_color`.
  4. `verse_number` accepts both numeric values and range strings (`"x-y"`). The app uses the first numeric value for ordering and chapter progress tracking.
- If app data looks stale after JSON changes, run:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```

## Planned Next Work
1. Further widget styling improvements (launcher compatibility and adaptive contrast).
2. Settings navigation polish and UX smoothing for post-pop sheet handoff.
