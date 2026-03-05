# Bhagvad Gita App - Documentation

## 1. Overview
Bhagvad Gita App is a Flutter app with a feed-first resume flow:
- App launches directly into feed at the last-read verse
- Chapter home screen is available in codebase but not the default launch route
- Vertical verse feed
- Verse details bottom sheet
- Settings actions for bookmarks, chapter progress, widget controls, and notifications
- Android home-screen widget support

## 2. Stack and Dependencies
- Flutter / Dart
- `google_fonts`: typography
- `flutter_local_notifications`: local notifications
- `shared_preferences`: local persistence
- `share_plus`: sharing text/images
- `path_provider`: temporary file storage for share image
- `timezone`: notification scheduling support

## 3. Project Layout
- `lib/main.dart`: app bootstrap and root route (`FeedScreen`)
- `lib/models/verse.dart`: verse model and JSON normalization
- `lib/screens/chapters_home_screen.dart`: chapter landing page + overall/chapter progress
- `lib/screens/feed_screen.dart`: vertical feed, search sheets, settings flow, bookmarks sheet
- `lib/screens/settings_screen.dart`: settings UI and `SettingsAction` return values
- `lib/services/verse_repository.dart`: asset loading/parsing/sorting
- `lib/services/reading_progress_service.dart`: chapter progress persistence
- `lib/services/notification_service.dart`: notification scheduling/toggle
- `lib/services/widget_service.dart`: widget method channel bridge
- `lib/widgets/verse_card.dart`: primary verse card + details bottom sheet
- `lib/widgets/glass_container.dart`: shared glassmorphism container
- `assets/data/verses.json`: in-app verse dataset
- `assets/images/`: theme-based feed backgrounds (`dark*`, `light*`)
- `android/app/src/main/kotlin/com/example/bhagvad_gita_app/MainActivity.kt`: widget channel handlers
- `android/app/src/main/kotlin/com/example/bhagvad_gita_app/VerseWidgetProvider.kt`: Android widget renderer

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

`Verse.fromJson` supports multiple source key variants and normalizes:
- IDs (`BG_CC_VV` fallback)
- chapter/verse numbers
- verse ranges in `verse_number` (for example `"5-6"` parses as `5` for ordering/progress)
- background color fallback palette
- fallback translation/deep-dive text

## 5. Current Dataset State
Source: `assets/data/verses.json`

- Total entries: **622**
- Non-summary verse rows: **604**
- Summary/recap rows (`verse_number = 0`): **18**
- Grouped/range verse rows (`verse_number = "x-y"`): **9**
- Chapter coverage: **1 to 17** (currently up to **17.8**)

Per chapter:
- Chapter 1: 49 entries (max verse 48)
- Chapter 2: 74 entries (max verse 73)
- Chapter 3: 43 entries (max verse 44)
- Chapter 4: 43 entries (max verse 42)
- Chapter 5: 31 entries (max verse 29)
- Chapter 6: 48 entries (max verse 47)
- Chapter 7: 33 entries (max verse 24)
- Chapter 8: 29 entries (max verse 28)
- Chapter 9: 36 entries (max verse 35)
- Chapter 10: 43 entries (max verse 43)
- Chapter 11: 55 entries (max verse 56)
- Chapter 12: 20 entries (max verse 21)
- Chapter 13: 35 entries (max verse 35)
- Chapter 14: 28 entries (max verse 28)
- Chapter 15: 21 entries (max verse 21)
- Chapter 16: 26 entries (max verse 25)
- Chapter 17: 8 entries (max verse 8)

## 6. Chapter Home Screen
`ChaptersHomeScreen`:
- Loads verses and saved chapter progress
- Shows overall reading progress (`read / total`)
- Shows chapter cards with per-chapter progress
- Opens `FeedScreen` at the first verse of the selected chapter
- Note: currently not used as default startup screen

## 7. Feed Screen Behavior
### Verse loading and position
- Loads from `VerseRepository`
- Restores last-read index unless `initialVerseId` is passed
- This is the default app entry flow on startup

### Gestures
- Vertical swipe: moves between verses (`PageView`)
- Horizontal swipe on the feed screen: opens current verse details
- Info button on card: opens the same details sheet
- Swipe guidance hint text is shown only on the first verse card (`index == 0`)

### Overflow-safe card layout
- Verse card uses adaptive/flexible layout for compact heights
- Action buttons use wrapping layout to avoid bottom overflow
- Main verse reading surface is transparent (no blur card), so background artwork remains visible.

### Background rendering
- Theme is user-selectable (`light` / `dark`) from Settings and persisted in SharedPreferences.
- Feed background is selected from theme-specific image pools:
  - Dark: `assets/images/dark.jpeg`, `assets/images/dark (2).jpeg`
  - Light: `assets/images/light.jpeg`, `assets/images/light (2).jpeg`
- On app start, one image is selected from the active theme pool with non-repeating immediate rotation logic.
- A theme-aware scrim plus dynamic chapter/verse color tint are layered on top for readability and visual continuity.

### Reading progress and history
- On page change, it persists:
  - current index
  - recent verse IDs
  - chapter progress
- Chapter progress now tracks exact visited verse IDs per chapter, so read chips are based on actual visited verses (not inferred by highest verse number).

### Search and jump
- Search supports chapter/verse pattern, ID, Sanskrit, transliteration, English
- Chapter-and-verse picker supports direct navigation
- Results are grouped by chapter

### Bookmarks
- Save/remove bookmark on verse card
- Settings -> Bookmarks opens saved verse sheet
- Each saved verse supports details, text share, and un-save

### Verse details section order
- Original Sanskrit
- Transliteration
- Deep Dive
- Word Meanings (if available)
- English Translation

## 8. Settings Screen
Sections:
- Notifications toggle
- Light theme toggle
- Widget language selector (`Sanskrit`, `English`)
- Widget mode selector (`fixed`, `random`)
- Chapter progress
- Bookmarks

Navigation behavior:
- Settings returns `SettingsAction`
- `FeedScreen` handles returned action and opens the selected sheet/flow (bookmarks/chapter progress)
- A short post-pop handoff delay is used before opening sheets to avoid route-transition race issues

## 9. Notification Service
- Persists enabled state in SharedPreferences
- Schedules 30 days ahead
- One notification per day:
  - 08:00 "Daily Verse"
- Requests Android notification permission when enabling notifications
- Uses repository-loaded verse list

## 10. Widget Integration (Android)
MethodChannel: `bhagvad_gita_app/widget`

Supported operations:
- `setVerseForWidget`
- `setWidgetLanguage`
- `setWidgetMode`
- `consumeWidgetLaunchAction`
- native -> Flutter callback: `onWidgetLaunchAction`

Widget behavior:
- Supports `fixed` and `random` mode
- In `fixed` mode:
  - tap widget opens app and launches verse picker flow
  - selected verse is pinned for widget display
- In `random` mode:
  - tap widget refreshes a random verse
- Text language follows widget language setting (`sanskrit`/`english`)
- Footer action opens the app

## 11. Data Update Workflow
When updating `assets/data/verses.json`:
1. Keep schema fields consistent (`id`, `chapter`, `verse_number`, etc.)
2. `verse_number` can be an integer (`17`) or grouped range string (`"5-6"`).
3. Ensure valid JSON
4. Rebuild app to avoid stale asset cache:

```bash
flutter clean
flutter pub get
flutter run
```

## 12. Verification Checklist
After code/data changes:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run`

Manual checks:
- On cold start, app opens directly in feed at last-read verse
- Theme mode is restored after restart
- Background image rotates within active theme pool after restart
- Chapter home (if opened) loads and opens each chapter
- Feed can scroll through the extended dataset (Chapters 1-17)
- Horizontal swipe and info icon open the same details sheet
- Swipe guidance hint appears only on the first verse card
- Settings -> Bookmarks opens bookmark list (does not drop to home unexpectedly)
- Chapter progress sheet opens and verse taps jump correctly
- Tapping an unread verse in chapter progress should not mark earlier verses as read by color
- Range rows (e.g., verse `5-6`) appear in correct chapter order
- No bottom `RenderFlex` overflow on small-height devices
- One daily notification is scheduled when enabled
- Widget fixed/random mode flows still work

## 13. Future Feature Proposal: Chapter Lessons
Planned idea (not implemented yet):
- Add a `Lessons` experience for Chapters `1` to `17` to explain what users should learn from each chapter.
- Target both:
  - first-time/new users (simple, practical explanation)
  - daily readers (deeper reflection and applied meaning)

Proposed lesson structure per chapter:
- `lesson_title`
- `core_lesson`
- `beginner_explanation`
- `deep_explanation`
- `daily_application` (how to apply today)
- `reflection_questions` (2-3 prompts)
- `key_verse_ids` (optional links to relevant verses in feed)

Possible data source:
- `assets/data/chapter_lessons.json` with one object per chapter.

Possible navigation:
- Chapter card action (`Open Lesson`)
- Feed top menu action (`Chapter Lesson`)
- Optional entry in Settings for quick lesson access

Notes:
- Keep language clear and practical.
- Lessons should be long-form enough to educate, but sectioned for readability.

## 14. Planned UI Work (Next)
Upcoming focus areas:
- Android widget UI refinement:
  - Improve layout hierarchy, typography, spacing, and visual balance.
  - Finalize text/background contrast for readability across launcher styles.
- Settings page UI improvement:
  - Refine section organization and interaction affordances.
  - Improve visual consistency with the feed's updated design direction.
