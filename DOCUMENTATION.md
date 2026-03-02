# Bhagvad Gita App - Documentation

## Project Overview
The Bhagvad Gita App is a modern, visually immersive Flutter application designed to deliver the wisdom of the Bhagavad Gita in a "Reels-style" vertical feed. It features a high-end "glassmorphism" UI, dynamic background transitions, and interactive features to enhance the user's spiritual journey.

---

## Technical Stack
- **Framework:** Flutter (Dart)
- **Key Dependencies:**
  - `google_fonts`: For elegant typography (Inter, Martel).
  - `share_plus`: For sharing verses as images.
  - `path_provider`: To handle temporary image storage for sharing.
  - `cupertino_icons`: For iOS-style iconography.

---

## Architecture

### 1. Data Model (`lib/models/verse.dart`)
The `Verse` class represents a single verse from the Gita. It includes:
- `id`: Unique identifier.
- `chapter` & `verseNumber`: Location in the Gita.
- `originalScript`: Sanskrit text in Devanagari.
- `transliteration`: Romanized Sanskrit.
- `translationEnglish`: Meaning in English.
- `deepDiveText`: Extended commentary or explanation.
- `backgroundHexColor`: Metadata for dynamic theme adjustment.
- `tags`: Keywords for categorization.

### 2. Main Screen (`lib/screens/feed_screen.dart`)
The core of the app, implementing the vertical scroll logic:
- **Data Loading:** Fetches data from `assets/data/verses.json` using `rootBundle`.
- **Navigation:** Uses a `PageView.builder` with `Axis.vertical`.
- **Features:**
  - **Language Toggle:** Instantly switch between Sanskrit and English translations.
  - **Saved Verses:** A simple state management system using a `Set` to track bookmarked verses, accessible via a bottom sheet.
  - **Dynamic Backgrounds:** Uses `AnimatedContainer` to transition background gradients smoothly as the user scrolls.

### 3. UI Components (`lib/widgets/`)
- **GlassContainer:** A custom wrapper utilizing `BackdropFilter` and `ClipRRect` to create a frosted glass effect (Glassmorphism). It supports customizable blur, opacity, and border radius.
- **VerseCard:** The primary unit of the feed.
  - Displays the verse content centered in a glass panel.
  - Contains action buttons: **Meaning** (opens details), **Save**, and **Share**.
  - Includes a `DraggableScrollableSheet` for deep-dive information.

---

## Key Features

### Reels-Style Interaction
The vertical feed allows users to swipe through verses seamlessly, providing a focused, meditative experience similar to modern social media content delivery.

### Screen Sharing
The app captures the current verse as a high-resolution PNG image using `RepaintBoundary`. This allows users to share beautifully formatted verses directly to other platforms (WhatsApp, Instagram, etc.).

### Meaning & Deep Dive
Each verse includes a "Deep Dive" section accessible via the "Meaning" button. This provides transliteration, English translation, and a detailed explanation in an elegant modal bottom sheet.

### Language Localization
Users can toggle between the original Sanskrit (`सं`) and the English translation (`EN`) with a single tap on the header.

---

## Data Source
The app's content is driven by a JSON file located at `assets/data/verses.json`. This makes the app easily extensible—adding new verses or updating translations only requires modifying this file.

---

## Performance & Optimization
- **Image Generation:** Uses `pixelRatio: 3.0` during screen capture to ensure shared images look sharp on all devices.
- **Smooth Transitions:** Background color changes are animated over 500ms to avoid jarring visual jumps.
- **Efficient Loading:** Verse data is decoded asynchronously during the `initState` of the main screen.
