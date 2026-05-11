# Contributing to Bookify Audio

First off, thank you for considering contributing to Bookify Audio! It's people like you who make this project a great resource for the community.

## 🌈 How Can I Contribute?

### Reporting Bugs
If you find a bug, please [open an issue](https://github.com/apon133/bookify_audio/issues). Be sure to include:
- A clear, descriptive title.
- Steps to reproduce the bug.
- Your device model (Android/iOS/Web).
- Relevant logs or screenshots.

### Suggesting Features
We love new ideas! If you want to suggest a new feature (like a sleep timer, bookmarking, or UI improvements), please open an issue and describe:
- What the feature is.
- Why it would be useful.
- How you think it should work.

### Code Contributions
1.  **Fork the repository**.
2.  **Create a feature branch**: `git checkout -b feature/my-cool-feature`.
3.  **Implement your changes**.
    - For UI/UX changes, work in `lib/screens`.
    - For logic/state changes, work in `lib/providers` or `lib/services`.
    - For data models, work in `lib/models`.
4.  **Test your changes** locally using `flutter run`.
5.  **Commit with a clear message**: `git commit -m 'feat: add sleep timer support'`.
6.  **Push to your fork** and **open a Pull Request**.

## 🛠️ Local Development Setup

1.  **Install Flutter SDK**: Ensure you have the latest stable version of Flutter.
2.  **Clone the Repo**: `git clone https://github.com/apon133/bookify_audio.git`.
3.  **Get Dependencies**: `flutter pub get`.
4.  **Run build_runner**: If you modify Isar/Hive models, run:
    `flutter pub run build_runner build --delete-conflicting-outputs`.
    *Note: We use a custom Isar generator located in `packages/isar_generator` for JS/WASM compatibility.*
5.  **Run the App**:
    - Mobile: `flutter run`
    - Web: `flutter run -d chrome`

## 📜 Coding Guidelines
- Follow the [Official Flutter Style Guide](https://flutter.dev/docs/development/tools/linting).
- Use **Riverpod** for state management.
- Ensure cross-platform compatibility (Web/Mobile) when adding new features.
- Keep performance in mind, especially for audio streaming and local storage.

## ⚖️ License
By contributing to Bookify Audio, you agree that your contributions will be licensed under the project's [GNU General Public License v3.0](LICENSE).

Happy coding! 🚀
