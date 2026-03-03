# Bhagvad Gita App - Documentation

## 1. Overview
Bhagvad Gita App is a Flutter application that delivers verses through a vertical, immersive feed. The app focuses on daily reflection with searchable content, persistent progress, saved verses, and scheduled notifications.

## 2. Stack and Dependencies
- Flutter / Dart
- `google_fonts`: typography
- `flutter_local_notifications`: local notifications
- `shared_preferences`: local persistence
- `share_plus`: share verse screenshots
- `path_provider`: temporary file storage for sharing
- `timezone`: notification scheduling support

## 3. Project Layout
- `lib/main.dart`: app bootstrap and service initialization.
- `lib/models/verse.dart`: verse model and JSON mapping.
- `lib/screens/feed_screen.dart`: main UI, feed logic, search, save/history, sharing.
- `lib/services/notification_service.dart`: notification setup, preference toggle, scheduling logic.
- `lib/widgets/glass_container.dart`: reusable frosted-glass UI wrapper.
- `lib/widgets/verse_card.dart`: verse card rendering and detail sheet.
- `assets/data/verses.json`: verse data source.

## 4. Data Model
`Verse` fields:
- `id`
- `chapter`
- `verseNumber`
- `originalScript`
- `transliteration`
- `translationEnglish`
- `deepDiveText`
- `backgroundHexColor`

These are parsed in `Verse.fromJson` from the local JSON asset.

## 5. Feed Screen Behavior
### Verse Loading
- Loads `assets/data/verses.json` via `rootBundle`.
- Parses JSON into `List<Verse>`.

### Navigation
- Uses `PageView.builder` with `Axis.vertical`.
- Tracks current page index for restore/history.

### Search and Jump
- Opens a search bottom sheet.
- Matches against chapter/verse pattern, verse ID, Sanskrit text, transliteration, and English translation.
- Selecting a result animates directly to the corresponding verse in the feed.

### Save and History Persistence
Uses `SharedPreferences` keys:
- `saved_verse_ids`
- `last_read_verse_index`
- `recent_verse_ids`

Behavior:
- Saved verses persist across app restarts.
- Last-read index is restored on launch.
- Recent verse list is maintained and used as default search suggestions.

### Sharing
- Captures visible content with `RepaintBoundary`.
- Writes PNG to temporary storage.
- Shares image + verse reference via `share_plus`.

## 6. Notification Service
### Initialization
- Initializes `FlutterLocalNotificationsPlugin`.
- If notifications are enabled, refreshes scheduled notifications during app startup.

### Toggle
- `toggleNotifications(bool enabled)` stores preference and either:
  - schedules daily notifications, or
  - cancels all notifications.

### Daily Scheduling Logic
- Schedules notifications for the next 30 days.
- Sends two notifications per day:
  - Morning: "Today's Verse"
  - Evening: "Random Verse"
- Uses deterministic day-based selection for today's verse and a deterministic random selection for random verse.

## 7. UI Components
### GlassContainer
Reusable translucent container used across cards and sheets.

### VerseCard
Displays current verse and actions:
- Meaning
- Save
- Share

Includes detailed bottom sheet with Sanskrit, transliteration, translation, and deep-dive explanation.

## 8. Dependency Update Workflow
From project root:
```bash
flutter pub outdated
flutter pub upgrade --major-versions
flutter pub get
```

## 9. Verification Checklist
After code changes:
1. `flutter pub get`
2. `flutter analyze`
3. `flutter run`

Manual checks:
- Search and jump opens correct verse.
- Saved verses persist after restart.
- Last-read verse is restored after restart.
- Notification toggle schedules/cancels as expected.
- Share action exports an image successfully.
