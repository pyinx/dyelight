# AI Photo Recolor Implementation Plan

> Executed inline (user asked to start development and verify with local Flutter, Android first).

**Goal:** Build the app described in `docs/superpowers/specs/2026-11-04-ai-photo-recolor-design.md`.

**Architecture:** Feature-first layers; `ImageEditProvider` adapter (images/edits, chat/completions); Riverpod + dio + hive_ce + secure storage; Cupertino-style UI.

**Tech Stack:** Flutter 3.41, flutter_riverpod, dio, flutter_secure_storage, hive_ce, image, image_picker, speech_to_text, permission_handler, gal, cupertino_icons.

---

- [ ] T1 Scaffold (`flutter create`), dependencies, Android/iOS manifest config
- [ ] T2 Core network: `api_error`, response parsing, both providers, URL normalization (TDD with dio mock adapter)
- [ ] T3 Core image: `preprocess` (≤2048 long edge, EXIF bake) (TDD)
- [ ] T4 Storage: secure store, settings repo, history repo
- [ ] T5 i18n (zh/en), prompt presets
- [ ] T6 Controllers: settings, edit (cancel, retry, errors), history
- [ ] T7 UI: tab shell, create/edit, generating, settings (+ test connection), history
- [ ] T8 Result: `CompareViewer` (synced zoom, slider painter, long-press), save, tweak
- [ ] T9 Verify: `flutter analyze`, `flutter test`, `flutter build apk --debug` (Android first), then iOS no-codesign build
