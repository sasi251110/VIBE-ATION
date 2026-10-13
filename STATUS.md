# Feature status (Android only)

Nothing here has been compiled or run by the author of this file. "Unit-tested" means tests were written, not that they have passed. Check CI.

## Implemented (written, unverified)
- Add audio files via picker, local library, search (title/artist/filename), sort, favorites, recents, playlists (all persisted in local preferences)
- Playback via just_audio: play/pause/seek/next/previous, queue (add/remove/reorder/clear/next-up), shuffle, repeat off/all/one, background playback + media notification (just_audio_background)
- Speed and pitch, "Slowed" preset, 5-band system equalizer with presets and custom presets, volume boost 100-300% (Android LoudnessEnhancer)
- Lyrics: paste/edit, import .lrc/.txt, synced highlight, sidecar .lrc discovery, font size
- Player layouts: vinyl (spin toggle), album, minimal; dark/AMOLED/light, accent color, performance mode

## NOT implemented
- Folder scanning (files are picked individually; the picker may copy them to app cache)
- Reading embedded tags/artwork; metadata editor (display-only or file)
- Reverb (so no "Slowed + Reverb"), bass/treble/balance/fades/compressor/crossfade/normalization
- Offline AI equalizer, audio-reactive visualizer, DJ mode, fullscreen visualizer
- SQLite (library uses SharedPreferences JSON), album search, signed release builds
- Windows (dropped by request)
