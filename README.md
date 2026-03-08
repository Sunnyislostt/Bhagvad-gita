# Bhagvad Gita App

A Flutter app that presents Bhagavad Gita verses in a vertical, reels-style experience with modern UI and practical daily-use features.

## Features
- App opens directly to the feed and resumes from the last-read verse.
- Chapter home screen (still available in codebase) with chapter-wise and overall reading progress.
- Vertical feed with smooth swipe navigation.
- Feed rendering path is optimized to reduce jank during verse swipes.
- Full-screen horizontal swipe on the feed to open verse details (same as info button).
- Light-theme verse details sheet uses the app's warm sand/beige palette with softer contrast so it matches the rest of the light theme while staying calm on the eyes.
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
- Summary and recap rows do not repeat the top `Chapter X` header when that context is already shown in the main content.
- Theme toggle (`Light` / `Dark`) with persistent preference.
- Background image follows selected theme:
  - Dark: `dark.jpeg`
  - Light: `light.jpeg`
- Dynamic verse-tint overlay on top of selected background.
- Background assets are precached and feed chrome avoids live blur on the main reading path for smoother frame pacing.
- Compatible devices can render at higher refresh rates (60 Hz / 120 Hz) when frame time stays within budget.
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

## Version Control
- Git remote is configured at `origin -> https://github.com/Sunnyislostt/Bhagvad-gita.git`
- Current working branch is `master`
- Temporary local helper files such as `tmp_fix_test.json` and `tmp_source_verse.json` are not part of the tracked app source

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
  1. `assets/data/verses.json` contains `726` entries across Chapters `1` to `18`.
  2. It includes:
     - `18` chapter overview rows
     - `18` recap rows
     - `10` grouped/range verse rows (e.g. `"verse_number": "5-6"`)
  3. Canonical Bhagavad Gita structure is `18` chapters and `700` verses; the current dataset covers all canonical verses and also includes overview, recap, and grouped rows for reading flow.
  4. It follows app schema: `id`, `chapter`, `verse_number`, `original_script`, `transliteration`, `word_meanings`, `translation_english`, `deep_dive_text`, `background_hex_color`.
  5. `verse_number` accepts both numeric values and range strings (`"x-y"`). The app uses the first numeric value for ordering and chapter progress tracking, while preserving the original label for display in the UI.
  6. Chapter overview and recap rows use `verse_number = 0`. They remain visible in the feed, but are excluded from reading progress totals and notification verse selection. Grouped/range rows preserve their original label for display.
  7. Overview and recap labels now use canonical chapter naming consistently across all 18 chapters.
  8. Overview and recap `deep_dive_text` entries were editorially normalized for a calmer, more neutral, and internally consistent tone.
- If app data looks stale after JSON changes, run:
  ```bash
  flutter clean
  flutter pub get
  flutter run
  ```
- Performance notes:
  1. Main feed page changes update a narrow repaint path instead of rebuilding the whole screen.
  2. Verse text fitting is cached, so long verses do not repeat expensive layout work on every rebuild.
  3. Glass blur is still used in modal surfaces, but always-visible feed controls now use lightweight translucent surfaces.
  4. High-refresh output depends on the device panel and whether the app stays under the frame budget in profile/release builds.

## Planned Next Work
1. Further widget styling improvements (launcher compatibility and adaptive contrast).
2. Settings interaction polish and section-level UX refinement.
3. Add a short 4-step onboarding flow covering welcome, gestures, preferences, and notifications/widget intro.
4. Explore feed-style Google AdMob native ads inserted as full-screen scroll items between verses, so users can swipe past ads naturally without banners.
