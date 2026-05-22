# Bookify Audio — YouTube to Audiobook Player for Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.22+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![WebAssembly](https://img.shields.io/badge/Web-WASM-654FF0?style=for-the-badge&logo=webassembly&logoColor=white)](https://webassembly.org/)
[![Android](https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPL--v3-blue?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/apon133/bookify_audio?style=for-the-badge)](https://github.com/apon133/bookify_audio/stargazers)
[![Forks](https://img.shields.io/github/forks/apon133/bookify_audio?style=for-the-badge)](https://github.com/apon133/bookify_audio/network/members)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge)](http://makeapullrequest.com)

> A high-performance Flutter app that transforms YouTube streams into a distraction-free audiobook experience — with background playback, SponsorBlock integration, persistent progress, and WASM-powered web support.

🌐 **[Live Demo](https://bookify-audio.netlify.app)**

---

## ✨ Features

### Audio Engine
- Stream high-fidelity audio directly from YouTube sources
- True background playback with screen off (powered by foreground tasks)
- Automatic sponsor/intro skipping via SponsorBlock integration
- Variable playback speed from 0.5x to 2.5x

### Library Management
- Persistent listening progress — never lose your place across sessions
- Deep recommendation engine based on your unique listening profile
- Near-instant search and library loads powered by the Isar NoSQL database
- Dual-storage architecture: Isar on Mobile, Hive on Web

### Design & UX
- Material 3 design with dynamic Dark/Light theming
- Glassmorphism UI with micro-animations
- Multi-language interface: English and Bengali

---

## 🛠️ Built With

| Component | Technology |
| :--- | :--- |
| Framework | Flutter 3.22+ |
| State Management | Riverpod |
| Database | Isar (Mobile) / Hive (Web) |
| Web Compilation | WebAssembly (WASM) |
| Background Execution | Foreground Task |
| Code Generation | Custom Isar Gen (53-bit ID hashing for WASM compatibility) |

---

## 🚀 Getting Started

### Prerequisites

- Flutter 3.22+
- Dart 3.4+

### Installation

**Clone the repository:**
```bash
git clone https://github.com/apon133/bookify_audio.git
cd bookify_audio
```

**Install dependencies:**
```bash
flutter pub get
```

**Run in development:**
```bash
# Mobile
flutter run

# Web
flutter run -d chrome
```

### Production Web Build (WASM)

```bash
flutter build web --wasm
```

> The codebase handles Isar's 64-bit integer IDs in a WASM-safe manner for full browser compatibility.

---

## 🗺️ Roadmap

- [x] Full-Text Search Engine
- [x] Writer Profile Biographies
- [x] Cross-Platform Storage Logic
- [x] SponsorBlock Integration
- [ ] Sleep Timer & Alarm *(upcoming)*
- [ ] User Ratings & Community Reviews
- [ ] Cloud Library Sync (Firebase/Supabase)

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch: `git checkout -b feature/AmazingFeature`
3. Commit your changes: `git commit -m 'Add some AmazingFeature'`
4. Push to the branch: `git push origin feature/AmazingFeature`
5. Open a Pull Request

---

## ⚖️ Disclaimer

Bookify Audio is an educational project and is not affiliated with YouTube. All audio is streamed directly from YouTube servers — no copyrighted files are hosted. Users are encouraged to support original creators on the YouTube platform.

---

## 📄 License

Distributed under the GNU General Public License v3.0. See [`LICENSE`](LICENSE) for details.

---

## 👤 Author

**Apon Ahmed** — [@apon133](https://github.com/apon133)

If this project helps you listen better, please give it a ⭐️ on GitHub!