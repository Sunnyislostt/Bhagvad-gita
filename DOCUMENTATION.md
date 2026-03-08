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
- `lib/screens/settings_screen.dart`: settings UI and in-settings action handlers
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
- `verseLabel`
- `originalScript`
- `transliteration`
- `wordMeanings`
- `translationEnglish`
- `deepDiveText`
- `backgroundHexColor`

`Verse.fromJson` supports multiple source key variants and normalizes:
- IDs (`BG_CC_VV` fallback)
- chapter/verse numbers
- verse ranges in `verse_number` (for example `"5-6"` parses as `5` for ordering/progress, while preserving `"5-6"` for display)
- background color fallback palette
- fallback translation/deep-dive text

## 5. Current Dataset State
Source: `assets/data/verses.json`

- Total entries: **726**
- Chapter overview rows: **18**
- Recap rows: **18**
- Grouped/range verse rows (`verse_number = "x-y"`): **10**
- Chapter coverage: **1 to 18**
- Canonical Bhagavad Gita structure: **18 chapters** and **700 verses**
- Current dataset covers all **700** canonical verses, plus overview and recap rows.
- Overview and recap labels use canonical chapter naming consistently across all chapters.
- Overview and recap body text has been editorially normalized to keep the summaries more neutral, less colloquial, and more internally consistent in tone.

Per chapter:
- Chapter 1: 49 entries (max verse 47)
- Chapter 2: 74 entries (max verse 72)
- Chapter 3: 45 entries (max verse 43)
- Chapter 4: 44 entries (max verse 42)
- Chapter 5: 31 entries (max verse 29)
- Chapter 6: 49 entries (max verse 47)
- Chapter 7: 32 entries (max verse 30)
- Chapter 8: 30 entries (max verse 28)
- Chapter 9: 36 entries (max verse 34)
- Chapter 10: 43 entries (max verse 42)
- Chapter 11: 55 entries (max verse 55)
- Chapter 12: 20 entries (max verse 20)
- Chapter 13: 35 entries (max verse 34)
- Chapter 14: 28 entries (max verse 27)
- Chapter 15: 21 entries (max verse 20)
- Chapter 16: 26 entries (max verse 24)
- Chapter 17: 29 entries (max verse 28)
- Chapter 18: 79 entries (max verse 78)

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
- The light-theme details sheet also uses the app's warm sand/beige light-theme palette with reduced glow, border contrast, and card brightness for a more eye-soothing reading surface.
- Swipe guidance hint text is shown only on the first verse card (`index == 0`)

### Overflow-safe card layout
- Verse card uses adaptive/flexible layout for compact heights
- Action buttons use wrapping layout to avoid bottom overflow
- Long verse text now tries smaller font sizes first and falls back to scrolling instead of truncating with ellipsis.
- Main verse reading surface is transparent (no blur card), so background artwork remains visible.

### Background rendering
- Theme is user-selectable (`light` / `dark`) from Settings and persisted in SharedPreferences.
- Feed background is selected directly by active theme:
  - Dark: `assets/images/dark.jpeg`
  - Light: `assets/images/light.jpeg`
- A theme-aware scrim plus dynamic chapter/verse color tint are layered on top for readability and visual continuity.
- Active feed backgrounds are precached to reduce first-frame decode work during startup and theme changes.

### Feed performance path
- `FeedScreen` tracks the active page with a `ValueNotifier<int>` so normal verse swipes do not rebuild the entire screen tree.
- The dynamic verse accent layer listens to the active index directly and updates independently from the rest of the page.
- Main feed chrome (`language`, `menu`, `settings`, notification preview) uses translucent containers without live backdrop blur to avoid expensive per-frame sampling over moving content.
- `PageView.builder` uses `allowImplicitScrolling: true` to keep adjacent verse pages ready for smoother swipes.
- Background images render with low filter quality plus gapless playback to reduce visual hitching while preserving the full-screen look.
- Verse ordering now uses type-aware sorting so chapter overview rows stay first, normal verses stay in canonical order, and recap rows stay at the end of each chapter.

### Reading progress and history
- On page change, it persists:
  - current index
  - recent verse IDs
  - chapter progress
- Chapter progress now tracks exact visited verse IDs per chapter, so read chips are based on actual visited verses (not inferred by highest verse number).
- Chapter overview and recap rows use `verse_number = 0` and remain visible in the feed, but they are excluded from chapter and overall progress totals.
- Range verse labels such as `4-5` are preserved in the UI even though ordering/progress still use the first numeric value.

### Search and jump
- Search supports chapter/verse pattern, ID, Sanskrit, transliteration, English
- Chapter-and-verse picker supports direct navigation
- Picker verse chips are responsive so non-numeric labels such as `Summary` and `Recap` fit without overflow.
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

### Verse card performance
- `VerseCard` is wrapped in a `RepaintBoundary` to reduce unnecessary repaints across page transitions.
- Long-verse font fitting is cached by verse/language/constraint combination, so repeated visits to the same card do not redo the full `TextPainter` search loop.
- If text still does not fit at the minimum font size, the card falls back to scrolling instead of truncation.

## 8. Settings Screen
Sections:
- Notifications toggle
- Light theme toggle
- Widget language selector (`Sanskrit`, `English`)
- Widget mode selector (`fixed`, `random`)
- Chapter progress
- Bookmarks

Navigation behavior:
- Settings can open Bookmarks and Chapter Progress sheets directly without forcing a route pop back to feed.
- Fixed widget verse can be selected directly from Settings (and also from home-screen widget tap).
- The fixed widget picker uses in-sheet chapter chips and verse chips instead of long dropdown lists.
- Notification settings copy is simplified to `Notifications` / `Verse reminders`.

## 9. Notification Service
- Persists enabled state in SharedPreferences
- Schedules 30 days ahead
- Two notifications per day:
  - 08:00 "Morning Verse"
  - 18:00 "Evening Verse"
- Requests Android notification permission when enabling notifications
- Uses repository-loaded verse list filtered to progress-counting verses (excluding chapter overview and recap rows)
- Notification taps open the exact verse from the payload without replacing the user's saved last-read position.

## 10. Widget Integration (Android)
MethodChannel: `bhagvad_gita_app/widget`

Supported operations:
- `setVerseForWidget`
- `setWidgetLanguage`
- `setWidgetMode`
- `setWidgetTheme`
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
- Widget background and verse surface styling follow the app's saved light/dark theme.
- Widget verse/reference text is rendered in white for readability across themes.
- Range verse references such as `4-5` are preserved in widget labels.

## 11. Data Update Workflow
When updating `assets/data/verses.json`:
1. Keep schema fields consistent (`id`, `chapter`, `verse_number`, etc.)
2. `verse_number` can be an integer (`17`) or grouped range string (`"5-6"`).
3. Range strings are displayed as-is in the UI, while the first numeric value is still used for ordering/progress.
4. Ensure valid JSON
5. Rebuild app to avoid stale asset cache:

```bash
flutter clean
flutter pub get
flutter run
```

Content note:
- Keep overview and recap titles aligned with canonical chapter names.
- Keep overview and recap body text neutral in tone, avoiding overly academic, colloquial, or tradition-specific claims stated as settled fact.

## 12. Verification Checklist
After code/data changes:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run`

Manual checks:
- On cold start, app opens directly in feed at last-read verse
- Theme mode is restored after restart
- Background image matches selected theme after restart
- Widget background updates when app theme changes
- Chapter home (if opened) loads and opens each chapter
- Feed can scroll through the full dataset (Chapters 1-18)
- Horizontal swipe and info icon open the same details sheet
- Swipe guidance hint appears only on the first verse card
- Settings -> Bookmarks opens bookmark list (does not drop to home unexpectedly)
- Chapter progress sheet opens and verse taps jump correctly
- Tapping an unread verse in chapter progress should not mark earlier verses as read by color
- Range rows (e.g., verse `5-6`) appear in correct chapter order and display their full label in the home/progress/widget UI
- Summary/Recap chips fit correctly in the chapter/verse picker
- No bottom `RenderFlex` overflow on small-height devices
- Long verses remain readable without `...` truncation on the main card
- Feed swipes remain smooth in `flutter run --profile` or release builds on a 60 Hz device
- Feed remains stable on high-refresh devices (for example 90 Hz / 120 Hz) without obvious hitching during consecutive verse swipes
- Morning and evening notifications are scheduled when enabled
- Notification tap opens the exact verse without changing the saved last-read position
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

## 15. Planned UX Work: Onboarding
Recommended onboarding approach:
- Keep onboarding short and focused.
- Use a 4-screen flow instead of a long tutorial.
- Match the app's background-image-led visual language instead of generic illustrations.

Proposed flow:
1. Welcome
   - Title: `Bhagavad Gita, one verse at a time`
   - Message: introduce the feed-first reading experience and resume flow
   - CTA: `Begin`
2. How It Works
   - Show the main gestures:
     - swipe up/down to move through verses
     - swipe sideways or tap info for details
     - save and share verses
   - CTA: `Continue`
3. Personalize
   - Let the user choose initial reading preferences:
     - Sanskrit or English
     - optional Light / Dark preview
   - CTA: `Set preferences`
4. Daily Practice
   - Explain morning/evening reminders and Android widget support
   - Actions:
     - `Enable notifications`
     - `Maybe later`
   - Note that widget setup can be done later from Settings
   - CTA: `Open app`

Design guidelines:
- Use large typography, minimal copy, and one primary CTA per screen.
- Keep the tone calm and practical rather than overly decorative.
- Add a simple progress indicator such as `1 / 4`.
- Do not ask for unnecessary permissions early.
- Request notification permission only when the notifications step is shown.
- Do not force widget setup during onboarding.

## 16. Future Monetization Idea: Feed Ads
Requested future direction:
- Add Google AdMob ads as full-page feed items inside the vertical verse scroll.
- Ads should appear as standalone pages between verses, similar to short-video or news-feed apps, so the user can swipe once more to continue reading.
- Do not use banner ads for this flow.
- Do not interrupt reading with popup-style interstitials for this flow.

Recommended technical direction:
- Use `google_mobile_ads`.
- Prefer `Native Ads` inserted into the feed data source rather than `InterstitialAd`.
- Build a mixed feed list containing both verse items and ad items.
- Render ad items as full-height pages inside the same `PageView` used by `FeedScreen`.
- Insert ads at a controlled interval, for example every `8` to `12` verses.
- Preload ads so feed scrolling remains smooth.

Why native ads:
- Interstitial ads are overlay-based and do not behave like normal feed pages.
- Native ads can be embedded in the scrollable feed and styled to fit the app's layout more naturally.

Important constraints:
- Ads must still be clearly identifiable as ads and comply with AdMob native ad attribution requirements.
- The ad page should not be disguised as a normal verse card.
- Avoid showing the first ad too early in the session.
- Keep the main reading experience primary; ad frequency should stay conservative.

Likely implementation files:
- `pubspec.yaml`
- `lib/main.dart`
- `lib/screens/feed_screen.dart`
- `android/app/src/main/AndroidManifest.xml`

Preferred rollout:
1. Start with Android support first.
2. Use AdMob test ad unit IDs during development.
3. Validate swipe smoothness and readability before enabling production ads.
