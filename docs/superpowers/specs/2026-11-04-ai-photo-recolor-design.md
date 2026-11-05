# AI Photo Restoration & Colorizer — Design

Date: 2026-11-04
Status: Approved in brainstorming; pending user review of this file.

## 1. Scope

A Flutter (iOS + Android) BYOK app that sends a user's photo to an OpenAI-compatible
endpoint to recolor/repair it, with a one-tap auto mode and a custom prompt/voice mode.
No accounts, no relay server, all history local.

**In v1:** OpenAI-compatible protocol only (`/v1/images/edits`, `/v1/chat/completions`).
**Out of v1:** ComfyUI and SD WebUI adapters (added later as new `ImageEditProvider`
implementations), WeChat mini-program, batch generation (multi-select import is allowed
but images are processed one at a time).

## 2. Stack

Flutter 3.41 (Impeller), `flutter_riverpod`, `dio`, `flutter_secure_storage`,
`hive_ce` (Isar is unmaintained), `image`, `image_picker`, `speech_to_text`,
`flutter_localizations` + `intl`, `cupertino_icons`, a gallery-save plugin, a permission plugin.

## 3. Architecture

```
lib/
  main.dart, app.dart
  core/
    network/  image_edit_provider.dart (interface), images_edits_provider.dart,
              chat_completions_provider.dart, api_client.dart, api_error.dart
    storage/  secure_store.dart, settings_repo.dart, history_repo.dart
    image/    preprocess.dart, image_saver.dart
    permissions/ permission_service.dart
    i18n/     ARB (zh, en), per-locale prompt presets
  features/   home, edit, result, history, settings
```

Flow: pick → `preprocess` (long edge ≤ 2048, EXIF baked in, JPEG/PNG) →
`EditController` (Riverpod `AsyncNotifier`) → `ImageEditProvider` with `CancelToken` →
result bytes → temp file → result screen → optional history + gallery save.

Boundaries: UI talks only to controllers; controllers talk only to the provider
interface and repos; only the two provider classes know wire formats; only
`secure_store` touches the API key.

## 4. Network

```dart
abstract class ImageEditProvider {
  Future<EditResult> edit(EditRequest req, CancelToken token);
  Future<ConnectionReport> testConnection();
}
```

- `ImagesEditsProvider`: multipart `POST {base}/images/edits` (`image`, `prompt`, `model`).
  Reads `data[0].b64_json`, falling back to `data[0].url` (downloaded).
- `ChatCompletionsProvider`: `POST {base}/chat/completions` with
  `[text, image_url(data:…base64)]`. Image extraction order: `message.images[].image_url.url`;
  a `data:image/...;base64,` string in content; an `http(s)` URL in content; otherwise
  `badResponse` with a short body excerpt. `temperature` applies here only.
- Common: timeout (default 60 s), custom headers, `Bearer` key from secure storage,
  trailing-slash trim on Base URL, plain `http://` to LAN IPs allowed.

| Error | Trigger | UI |
|---|---|---|
| timeout | connect/send/receive timeout | Dialog: timed out, generation can be slow; Retry; check LAN/service |
| safety | HTTP 400 | Safety-review message, plus the server's own message when present |
| auth | 401/403 | Check API key |
| network | refused/DNS | Check Base URL and LAN connectivity |
| badResponse | 5xx or no image found | Status + short excerpt |
| cancelled | user cancel | Silent; back to edit screen |

Connection test: `GET {base}/models` (no image). Reports reachable, auth OK, and whether
the configured Model ID is listed. A 404 on `/models` reports "reachable, model list
unavailable", not failure.

## 5. Result viewer, memory, storage

- `CompareViewer`: one shared `TransformationController` for both images (synced
  zoom/pan). `CustomPainter` clips the "after" image at the slider x; slider position in a
  `ValueNotifier` so only the painter and handle rebuild. Long press shows the original.
- Images decoded with `ResizeImage` (≈ screen size × DPR); full-res file kept for saving;
  providers evicted from the image cache on dispose.
- Save: full-res to gallery. iOS add-only photos permission; Android MediaStore (no
  permission on API 29+, storage permission below).
- "Tweak and regenerate" keeps prompt and mode and reuses the preprocessed source.
- API key in `flutter_secure_storage`. Settings and history metadata in `hive_ce`; history
  images are files under app documents with paths in Hive; deleting an entry deletes files.

## 6. i18n, permissions, platform

- zh + en ARB; follows system locale with manual override. Chips, auto-mode system prompt,
  and error messages have per-locale variants.
- `PermissionService` for photos/camera/mic; permanent denial opens a dialog deep-linking
  to system Settings. Speech uses zh_CN / en_US; mic button hidden if unavailable.
- Android: edge-to-edge, `usesCleartextTraffic`. iOS: safe areas/Home Bar,
  `NSLocalNetworkUsageDescription` and ATS exception for local HTTP.

## 7. UI/UX (Apple style, mobile native)

Cupertino-style UI on both platforms (Android keeps iOS styling by decision; predictive back
enabled).

- Typography: system font, large-title/title/body/caption hierarchy, respects text scale.
- Color: iOS system colors, automatic light/dark; grouped backgrounds; system-blue accent.
- Shape/depth: continuous-corner (squircle) shapes, minimal shadow, `BackdropFilter` blur on
  bars and floating controls. Icons from `cupertino_icons`.
- Haptics: light impact on slider center crossing, chip selection, mode switch; success/error
  on completion/failure.
- Navigation: `CupertinoApp`, `CupertinoPageRoute` (swipe-back), `CupertinoSliverNavigationBar`
  large titles, `CupertinoTabBar` with Create / History / Settings, inset-grouped settings
  lists, `CupertinoActionSheet` for photo source, `CupertinoAlertDialog` for errors.
  Auto/custom mode via `CupertinoSlidingSegmentedControl`.
- Create: large empty state, one primary action plus camera; after selection, image card,
  mode control, full-width primary button above the Home Bar.
- Generating: photo stays visible with shimmer overlay, rotating status text, Cancel button;
  no blocking full-screen spinner.
- Result: full-bleed image under the status bar, floating translucent toolbar (Save / Tweak), tap toggles chrome. Spring transitions, Hero from history; honors reduce-motion.
- Accessibility: semantic labels, ≥ 44×44 pt targets, compare slider exposes
  increment/decrement actions.

## 8. Testing and verification

- Unit: preprocess size cap and EXIF, response parsing for all image-location formats, error
  mapping, Base URL normalization.
- Provider tests with a `dio` mock adapter (no real network).
- Widget: compare slider, cancel flow.
- Gates: `flutter analyze`, `flutter test`, `flutter build apk --debug`,
  `flutter build ios --no-codesign`.
- Not verifiable without a device and live endpoint: camera, microphone, photo save, real
  model calls. These will be reported as unverified.

## 9. Assumptions

- A 400 is shown with the safety message but includes the server's message, since some
  servers use 400 for malformed requests.
- History uses `hive_ce` for metadata, files for images.
