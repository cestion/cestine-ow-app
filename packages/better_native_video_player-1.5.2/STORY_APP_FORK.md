# Story App local fork

Base package: `better_native_video_player` 1.5.2.

## Local changes

- Emits `firstFrame` after the native output surface presents its first frame.
- Emits throttled `frameRendered` heartbeats (at most every 250 ms).
- Android uses Media3 `onRenderedFirstFrame` and
  `VideoFrameMetadataListener`.
- iOS lightweight views use `AVPlayerLayer.isReadyForDisplay` for first-frame
  confirmation and `AVPlayerItemVideoOutput` for frame liveness.
- iOS texture views report frames from their existing
  `AVPlayerItemVideoOutput`, avoiding a second output.
- Dart maps these events to `PlayerControlState.firstFrameRendered` and
  `PlayerControlState.frameRendered`.

The app consumes this fork through `dependency_overrides` in the root
`pubspec.yaml`. Keep the event names and payloads backward-compatible if the
fork is moved to a separate Git repository.
