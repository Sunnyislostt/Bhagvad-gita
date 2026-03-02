# Bhagvad Gita App 🕉️

A modern, visually immersive Flutter application designed to deliver the wisdom of the Bhagavad Gita through a "Reels-style" vertical feed.

## ✨ Features

- **Reels-Style Feed:** Swipe vertically through verses for a focused, meditative experience.
- **Glassmorphism UI:** Elegant, modern design with frosted glass effects.
- **Bilingual Support:** Toggle between original Sanskrit (Devanagari) and English translations.
- **Deep Dive:** Detailed meaning, transliteration, and commentary for every verse.
- **Dynamic Themes:** Background colors transition smoothly based on the verse's theme.
- **Save & Bookmark:** Keep track of your favorite verses in a dedicated saved list.
- **Screen Sharing:** Capture and share beautifully formatted verses as high-quality images.

## 🛠️ Tech Stack

- **Framework:** Flutter
- **Language:** Dart
- **Typography:** Google Fonts (Inter, Martel)
- **State Management:** Local State (StatefulWidgets)
- **Data Source:** JSON-based local assets

## 📖 Documentation

For a detailed breakdown of the project's architecture, data models, and component structure, please refer to the [DOCUMENTATION.md](./DOCUMENTATION.md) file.

## 🚀 Getting Started

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/Sunnyislostt/Bhagvad-gita.git
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

## 📂 Project Structure

- `lib/models/`: Data models for Gita verses.
- `lib/screens/`: Primary app screens (Feed, Saved list).
- `lib/widgets/`: Reusable UI components like `GlassContainer` and `VerseCard`.
- `assets/data/`: JSON data containing the Gita verses.
