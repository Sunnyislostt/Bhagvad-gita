# Bhagvad Gita App - Documentation

## 1. Overview
Bhagvad Gita App is a Flutter application with a chapter-first reading flow:
- Chapter home screen with progress overview
- Vertical verse feed for immersive reading
- Structured search and direct verse jump
- Reader language switch in-feed (Sanskrit, English only)
- Settings-driven tools (notifications, bookmarks, chapter progress, widget controls)
- Android home-screen widget support

The app currently uses a custom curated starter dataset of 50 verses and is designed for incremental expansion.

## 2. Stack and Dependencies
- Flutter / Dart
- `google_fonts`: typography
- `flutter_local_notifications`: local notifications
- `shared_preferences`: local persistence
- `share_plus`: sharing verse content
- `path_provider`: temporary storage for shared images
- `timezone`: notification scheduling support

## 3. Project Layout
- `lib/main.dart`: app bootstrap and root route (`ChaptersHomeScreen`)
- `lib/models/verse.dart`: verse model and schema mapping/normalization
- `lib/screens/chapters_home_screen.dart`: chapter landing page with progress cards
- `lib/screens/feed_screen.dart`: reels-style verse feed, search, bookmarks, chapter-progress jump sheet
- `lib/screens/settings_screen.dart`: themed settings page and action return flow
- `lib/services/verse_repository.dart`: unified verse loader and merge strategy
- `lib/services/reading_progress_service.dart`: per-chapter progress persistence
- `lib/services/notification_service.dart`: daily notification setup/scheduling
- `lib/services/widget_service.dart`: Flutter-to-Android MethodChannel bridge
- `lib/widgets/verse_card.dart`: verse card + details/meaning UI
- `lib/widgets/glass_container.dart`: reusable glassmorphism container
- `assets/data/verses.json`: current custom verse dataset
- `tools/generate_custom_50_verses.ps1`: script to generate/reset the 50-verse starter set
- `android/app/src/main/kotlin/com/example/bhagvad_gita_app/MainActivity.kt`: widget channel handlers
- `android/app/src/main/kotlin/com/example/bhagvad_gita_app/VerseWidgetProvider.kt`: Android widget rendering/refresh

## 4. Data Model
`Verse` fields:
- `id`
- `chapter`
- `verseNumber`
- `originalScript`
- `transliteration`
- `wordMeanings`
- `translationEnglish`
- `deepDiveText`
- `backgroundHexColor`

Model parsing is handled by `Verse.fromJson` and supports multiple source variants while output stays in the normalized app format above.

## 5. Current Dataset State
- Current in-app dataset size: **50 verses**
- Current range: **`BG_01_01` to `BG_02_03`**
- Dataset source is `assets/data/verses.json`.

## 6. Chapter Home Screen
`ChaptersHomeScreen` provides:
- Overall reading progress bar (`read verses / total verses`)
- Chapter cards with:
  - chapter label
  - read count
  - chapter progress percentage
- Tap chapter card to open `FeedScreen` at that chapter's first verse

After returning from feed, progress is reloaded to keep cards current.

## 7. Feed Screen Behavior
### Verse Loading
- Uses `VerseRepository` for source loading.
- Restores last-read index unless an `initialVerseId` is provided.

### Reading Progress Tracking
- Progress is recorded when:
  - feed initializes on a verse
  - user swipes to a new verse
- Progress is stored chapter-wise via `ReadingProgressService`.

### Search and Jump
- Text search supports chapter/verse patterns, verse ID, Sanskrit, transliteration, and English.
- Segmented picker allows direct chapter -> verse selection.
- Search results are grouped by chapter for quick scanning.

### Language Handling
- Feed display language supports only `sanskrit` and `english`.
- Any legacy language values such as `hi` or `hindi` are normalized to `english` on load.

### Bookmarks
- Saved verses open in a bottom sheet with:
  - meaning/details
  - share
  - remove bookmark

### Chapter Progress Jump Sheet
- Opened from Settings action.
- Shows chapter progress bars and tappable verse chips.
- Tapping a verse chip closes the sheet and jumps feed scroll to that exact verse.

## 8. Settings Screen
Settings is a dedicated full page and currently includes:
- Notifications toggle
- Widget language selector (`Sanskrit`, `English`)
- Choose widget verse
- Chapter progress action
- Bookmarks action

Actions return to `FeedScreen` as `SettingsAction` values, then feed opens the corresponding sheet/flow.

## 9. Notification Service
### Scheduling
- Schedules notifications for the next 30 days.
- Two notifications per day:
  - Morning: Today's Verse
  - Evening: Random Verse

### Data Source
- Notification verses are loaded through `VerseRepository`.

## 10. Widget Integration (Android)
### Flutter Bridge
`WidgetService` calls MethodChannel `bhagvad_gita_app/widget`:
- `setVerseForWidget`
- `setWidgetLanguage`

### Widget Display
- Shows app title + language chip + verse text.
- Verse text changes with widget language setting (`Sanskrit`, `English`).
- Chapter/verse reference is shown below the header.
- Widget language persistence also uses only `sanskrit`/`english` values.

## 11. Custom Database Workflow
### Regenerate the current 50-verse starter dataset
```bash
powershell -ExecutionPolicy Bypass -File tools/generate_custom_50_verses.ps1
```

### Strategy for full custom expansion
- Extend source content chapter by chapter.
- Keep normalized schema stable.
- Keep `id` format as `BG_CC_VV`.
- Maintain high-quality `translation_english` and `deep_dive_text` per verse.

## 12. Verification Checklist
After code/data changes:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run`

Manual checks:
- Chapter home appears first and opens feed correctly.
- Chapter and overall progress update after reading/swiping.
- Feed language switch cycles correctly: `SA -> EN -> SA`.
- Legacy `HI`/`Hindi` preference values do not appear in UI and resolve to English.
- Widget language updates correctly for Sanskrit/English.
- Settings -> Chapter progress opens and verse tap jumps to exact scroll verse.
- Search direct picker and grouped results work.
- Bookmarks, share, and details are stable.
- Notifications and widget flows still behave as expected.
