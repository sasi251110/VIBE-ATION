# Architecture (Phase 1)

- State: Riverpod. Settings persisted with shared_preferences.
- `lib/core/theme`: tokens, settings model, controller, ThemeData builder.
- `lib/features/*`: one folder per feature; folders are added only when implemented.
- Planned audio engine: media_kit behind an `AudioEngine` interface (pending approval).
- Fonts: system fonts only (no runtime font downloads, to stay offline).
