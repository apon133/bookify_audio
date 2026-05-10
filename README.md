# 📚 Bookify Audio: YouTube to Audiobook Converter

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Isar](https://img.shields.io/badge/Database-Isar-blue?style=for-the-badge)](https://isar.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-lightgrey?style=for-the-badge)](https://riverpod.dev)

**Bookify Audio** is a high-performance, open-source Flutter application that transforms YouTube videos into a premium audiobook experience. Designed for listeners who want to enjoy educational content, stories, and lectures without the distractions of video, Bookify Audio provides a seamless, audio-only background playback environment.

---

## 🌟 Key Features

### 🎧 Premium Audio Experience
- **YouTube to Audio**: Instantly convert any YouTube video URL into a high-quality audio stream.
- **Background Playback**: Keep listening even when your screen is off or you're using other apps.
- **Smart Media Player**: Features like playback speed control (0.5x to 2.0x), skip forward/backward, and persistent position saving.
- **SponsorBlock Integration**: Automatically skip sponsored segments in videos for an uninterrupted experience.

### 📱 Modern & Intuitive UI
- **Dynamic Mini Player**: Always-accessible controls with real-time status indicators.
- **Fluid Animations**: Smooth Hero transitions and tactile scrolling effects.
- **Dark & Light Mode**: A beautifully curated design system that adapts to your environment.
- **Personalized Recommendations**: An AI-driven suggestion system based on your listening habits.

### offline & Management
- **Offline Listening**: Download your favorite books for offline use.
- **Library Management**: Organize your listening with History, Liked books, and custom Playlists.
- **Fast Local Storage**: Powered by **Isar Database** for lightning-fast search and data retrieval.

---

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev) (Cross-platform Excellence)
- **State Management**: [Riverpod](https://riverpod.dev) (Reactive & Robust)
- **Database**: [Isar](https://isar.dev) (NoSQL High-speed Database)
- **Audio Engine**: `youtube_player_iframe` (Web) & `youtube_player_flutter` (Mobile)
- **Background Task**: `flutter_foreground_task` (Android/iOS)
- **Network**: `http`, `youtube_explode_dart`
- **UI Architecture**: Model-View-Controller (MVC) with clean separation of services.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (Channel Stable)
- Chrome (for Web) or Android/iOS device

### Installation
1.  **Clone the Repository**:
    ```bash
    git clone https://github.com/apon133/bookify_audio.git
    cd bookify_audio
    ```
2.  **Install Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the Application**:
    ```bash
    flutter run -d chrome  # For Web
    flutter run            # For Mobile
    ```

### Web Production Build
To build the highly optimized production version for the web:
```bash
flutter build web
```
*Note: Standard web builds are recommended for maximum compatibility with Isar and underlying audio plugins.*

---

## 📈 Roadmap & Contributions

We are constantly evolving! Current progress:

- [x] **Local Notifications** & Media Controls ✅
- [x] **Background Playback** Persistence ✅
- [x] **Full Search** Capabilities ✅
- [x] **Download** Functionality ✅
- [x] **Multi-language Support** (English/Bengali) ✅
- [ ] **Sleep Timer** (Next Release)
- [ ] **Audio Book Ratings & Social Reviews**
- [ ] **Cloud Sync** for User Libraries

**Contributions are highly encouraged!** Whether it's a bug fix, a new feature, or a design improvement, please feel free to fork and PR.

---

## ⚖️ Disclaimer & Attribution

**Bookify Audio** is a free, non-commercial tool. We respect content creators:
- This app is intended for personal, non-commercial use only.
- All audio content is streamed directly from YouTube; we encourage users to support original creators by subscribing to their channels.
- No copyrighted material is hosted on our servers.

---

## 🤝 Contact & Feedback

Have a suggestion or found a bug? [Open an issue](https://github.com/apon133/bookify_audio/issues) or reach out to the development team.

**Let's make audiobooks more accessible together!** 🎧📖
