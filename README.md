# PackageHub

PackageHub is a Flutter app for organizing pickup credentials and quickly opening
the corresponding identity-provider pages.

## Included features

- Import pickup information from images with OCR and review the parsed fields.
- Batch review imported items and detect possible duplicate tracking numbers.
- Store, edit, group, and search pickup credentials locally.
- Resolve pickup zones on the station map using station-specific rules.
- Launch supported identity-provider pages directly from a credential.

## Development

```bash
flutter pub get
flutter test
```

The repository intentionally excludes local secrets, Flutter build output, and
release packages. Keep credentials in local `.env` files or platform keystores;
use `.env.example` for values that are safe to document.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
