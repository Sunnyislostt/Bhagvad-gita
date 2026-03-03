# Bhagvad Gita App

A Flutter app that presents Bhagavad Gita verses in a vertical, reels-style experience with modern UI and practical daily-use features.

## Features
- Vertical feed with smooth swipe navigation.
- Search and jump to verses by chapter/verse, verse ID, Sanskrit, transliteration, or English text.
- Language toggle between Sanskrit and English view.
- Saved verses with persistent storage.
- Reading history persistence (last-read verse and recent verses).
- Daily notifications with two entries:
  - Today's Verse
  - Random Verse
- Verse detail bottom sheet with transliteration, translation, and deep-dive text.
- Share the current verse as an image.
- Dynamic gradient backgrounds based on verse metadata.

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
- `lib/screens/` primary screens and app flow.
- `lib/services/` service layer (notifications).
- `lib/widgets/` reusable UI components.
- `assets/data/` verse source JSON.

## Notes
- Android notifications require notification permissions (runtime on newer Android versions).
- Daily notifications are scheduled in-app and refreshed when the app initializes.
