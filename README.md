# yu_ni_player

A unified Flutter video player plugin with **multi-engine support**. Configure different player backends per platform — all through a single, consistent API.

[![pub version](https://img.shields.io/badge/pub-1.0.0-blue)](https://github.com/lurongshuang/yu_ni_player)
[![Flutter](https://img.shields.io/badge/Flutter-≥3.10.0-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-≥3.0.0-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Features

- **Unified API** — One interface for all player backends: `play()`, `pause()`, `seek()`, `setRate()`, `setMute()`, etc.
- **Multi-engine** — Register different engines per platform via a simple config map.
- **LRU object pool** — Automatic player lifecycle management with configurable active/recycled limits. No manual create/destroy needed.
- **Fullscreen** — Built-in fullscreen support via `Navigator.push` (no system orientation change). Supports manual portrait/landscape rotation inside fullscreen.
- **Default controls** — Ready-to-use control bar with progress, seek, rate, mute, and fullscreen buttons. Auto-hides after 3 seconds.
- **Custom controls** — Replace the entire control bar via `controlsBuilder`.
- **Reactive state** — `ValueNotifier<YuNiPlayerState>` for easy UI binding.
- **Open extension** — Implement `YuNiPlayerEngine` to integrate any video SDK.

---

## Platform Support

| Platform | Recommended Engine | Package |
|---|---|---|
| iOS | `TXPlayerEngine` | `super_player` |
| Android | `TXPlayerEngine` | `super_player` |
| macOS | `VideoPlayerKitEngine` | `video_player` |
| Windows | `VideoPlayerKitEngine` | `video_player` |
| Web | `VideoPlayerKitEngine` | `video_player` |
| Linux | `MediaKitEngine` | `media_kit` |

> `VideoPlayerKitEngine` also works on iOS/Android as a fallback when `super_player` is not available.

---

## Installation

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  yu_ni_player:
    git:
      url: https://github.com/lurongshuang/yu_ni_player.git
      ref: main

  # Required for VideoPlayerKitEngine (macOS / Windows / Web / iOS / Android)
  video_player: ^2.9.2

  # Optional: TXPlayerEngine (iOS / Android)
  # super_player: ^11.x.x

  # Optional: MediaKitEngine (Linux)
  # media_kit: ^1.x.x
  # media_kit_video: ^1.x.x
  # media_kit_libs_video: ^1.x.x
```

---

## Quick Start

### 1. Initialize at app startup

```dart
import 'package:yu_ni_player/yu_ni_player.dart';
import 'package:yu_ni_player/engines/video_player_kit_engine.dart';
// import 'package:yu_ni_player/engines/tx_player_engine.dart'; // for TXPlayer

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Optional: initialize TXPlayer license (iOS/Android only)
  // TXPlayerEngine.initLicense(
  //   'https://your-license-url',
  //   'your-license-key',
  // );

  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.ios:        (src) => VideoPlayerKitEngine(src),
      PlatformKey.android:    (src) => VideoPlayerKitEngine(src),
      PlatformKey.macos:      (src) => VideoPlayerKitEngine(src),
      PlatformKey.windows:    (src) => VideoPlayerKitEngine(src),
      PlatformKey.web:        (src) => VideoPlayerKitEngine(src),
      PlatformKey.defaultKey: (src) => VideoPlayerKitEngine(src),
    },
    maxActiveCount: 3,   // max simultaneous active players
    maxRecycledCount: 2, // max recycled (reusable) players
  ));

  runApp(const MyApp());
}
```

### 2. Basic usage — single player

```dart
class VideoPage extends StatefulWidget {
  const VideoPage({super.key});
  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late YuNiPlayerEngine _player;

  @override
  void initState() {
    super.initState();
    final source = YuNiVideoSource(
      id: 'my_video',
      url: 'https://example.com/video.mp4',
    );
    _player = YuNiPlayerPool.instance.acquire(source);
    _player.init(config: const YuNiEngineConfig(autoPlay: true));
  }

  @override
  void dispose() {
    YuNiPlayerPool.instance.release(_player.videoSource);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YuNiPlayer(
      player: _player,
      backgroundColor: Colors.black,
      showDefaultControls: true,   // built-in control bar
      allowFullscreen: true,
      onFullscreenChanged: (isFullscreen) {
        debugPrint('Fullscreen: $isFullscreen');
      },
    );
  }
}
```

### 3. Custom loading / error UI

```dart
YuNiPlayer(
  player: _player,
  backgroundColor: Colors.black,
  loadingBuilder: (ctx) => const Center(
    child: CircularProgressIndicator(color: Colors.white),
  ),
  errorBuilder: (ctx, error) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 48),
        const SizedBox(height: 8),
        Text('$error', style: const TextStyle(color: Colors.white)),
      ],
    ),
  ),
)
```

---

## Object Pool

`YuNiPlayerPool` manages player instances using an **LRU (Least Recently Used)** strategy, minimizing the cost of creating and destroying native player instances.

### How it works

```
acquire(source)
  ├── Hit active cache → refresh LRU position, return
  ├── Miss → try recycled pool (LIFO) → reuse instance
  └── Recycled empty → create new instance via YuNiPlayerFactory

release(source)
  └── Move to recycled pool (or dispose if pool is full)

LRU eviction
  └── When active pool exceeds maxActiveCount:
      evict oldest non-currentPlayer entry → recycled pool
```

### Usage

```dart
// Acquire a player (creates or reuses)
final source = YuNiVideoSource(id: 'video_1', url: 'https://...');
final player = YuNiPlayerPool.instance.acquire(source);

// Mark as current (protected from LRU eviction)
YuNiPlayerPool.instance.currentPlayer = player;

// Release when done (moves to recycled pool)
await YuNiPlayerPool.instance.release(source);

// Dispose all (e.g., on page dispose)
await YuNiPlayerPool.instance.disposeAll();
```

### Feed list pattern

```dart
class FeedPage extends StatefulWidget { ... }

class _FeedPageState extends State<FeedPage> {
  final _pool = YuNiPlayerPool.instance;

  @override
  void initState() {
    super.initState();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);
  }

  @override
  void dispose() {
    for (final video in videos) {
      _pool.release(YuNiVideoSource(id: video.id, url: video.url));
    }
    super.dispose();
  }

  void _playVideo(int index) async {
    final source = YuNiVideoSource(id: videos[index].id, url: videos[index].url);
    final engine = _pool.acquire(source);
    _pool.currentPlayer = engine;

    if (!engine.isPrepared) {
      await engine.init(config: const YuNiEngineConfig(autoPlay: true, loop: true));
    } else if (!engine.isPlaying) {
      await engine.play();
    }
  }
}
```

---

## Fullscreen

Fullscreen is implemented via `Navigator.push` with a transparent route — **no system orientation change**, no impact on other pages.

### Behavior

- **Enter fullscreen**: Pushes a fullscreen route, hides system UI (`immersiveSticky`).
- **Exit fullscreen**: Pops the route (via button or system back key), restores system UI.
- **Rotation button**: Inside fullscreen, a rotation button toggles between portrait and landscape video layout using `RotatedBox` (layout-aware rotation, correct aspect ratio).
- **System back key**: Intercepted by `PopScope`, exits fullscreen instead of navigating back.

### Control bar layout in fullscreen

```
[▶/⏸] [00:00 / 01:30]  ···  [倍速] [🔊] [⟳ rotate] [⛶ exit]
```

### Custom fullscreen controls

```dart
YuNiPlayer(
  player: _player,
  controlsBuilder: (ctx, controls) {
    return MyCustomControls(controls: controls);
  },
)
```

The `controlsBuilder` is used for both normal and fullscreen modes. `controls.isFullscreen` tells you which mode you're in.

---

## Custom Controls

Replace the entire control bar with `controlsBuilder`:

```dart
YuNiPlayer(
  player: _player,
  controlsBuilder: (BuildContext ctx, YuNiControlsContext controls) {
    return Stack(
      children: [
        // Progress bar
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Slider(
            value: controls.progress,
            onChanged: (v) => controls.onSeek(v * controls.duration.inSeconds),
          ),
        ),
        // Play/pause
        Center(
          child: IconButton(
            icon: Icon(controls.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: controls.isPlaying ? controls.onPause : controls.onPlay,
          ),
        ),
      ],
    );
  },
)
```

### `YuNiControlsContext` reference

| Property | Type | Description |
|---|---|---|
| `state` | `YuNiPlayerState` | Current player state |
| `position` | `Duration` | Current playback position |
| `duration` | `Duration` | Total video duration |
| `bufferPercent` | `int` | Buffer progress (0–100) |
| `isFullscreen` | `bool` | Whether in fullscreen mode |
| `isMuted` | `bool` | Whether muted |
| `rate` | `double` | Current playback rate |
| `progress` | `double` | Position / duration (0.0–1.0) |
| `isPlaying` | `bool` | Shorthand for state == playing |
| `isLoading` | `bool` | Shorthand for loading/buffering |
| `isError` | `bool` | Shorthand for error state |
| `isCompleted` | `bool` | Shorthand for completed state |

| Callback | Signature | Description |
|---|---|---|
| `onPlay` | `VoidCallback` | Start/resume playback |
| `onPause` | `VoidCallback` | Pause playback |
| `onSeek` | `void Function(double seconds)` | Seek to position |
| `onToggleFullscreen` | `VoidCallback` | Toggle fullscreen |
| `onSetRate` | `void Function(double rate)` | Set playback rate |
| `onSetMute` | `void Function(bool mute)` | Set mute state |

---

## Custom Engine

Implement `YuNiPlayerEngine` to integrate any video SDK:

```dart
class MyCustomEngine extends YuNiPlayerEngine {
  MyCustomEngine(super.videoSource);

  MySDKController? _controller;

  @override
  bool get isPrepared => _controller != null && _controller!.isReady;

  @override
  Future<void> performInit() async {
    _controller = MySDKController();
    await _controller!.initialize(videoSource.url!);
    instanceCode.value = _controller.hashCode; // triggers UI rebuild
  }

  @override
  Future<void> performPlay() async => _controller?.play();

  @override
  Future<void> performPause() async => _controller?.pause();

  @override
  Future<void> performSeek(double seconds) async =>
      _controller?.seekTo(Duration(seconds: seconds.toInt()));

  @override
  Future<void> performDispose() async {
    await _controller?.dispose();
    _controller = null;
  }

  @override
  Future<void> performRelease() async {
    await _controller?.dispose();
    _controller = null;
    instanceCode.value++; // notify UI to clear old view
  }

  @override
  Widget buildView() {
    if (_controller == null) return const SizedBox.shrink();
    return MySDKVideoView(controller: _controller!);
  }

  @override
  Future<void> setLoop(bool loop) async => _controller?.setLoop(loop);

  @override
  Future<void> setVolume(double volume) async => _controller?.setVolume(volume);

  @override
  Future<void> setMute(bool mute) async => _controller?.setMute(mute);

  @override
  Future<void> setRate(double rate) async => _controller?.setRate(rate);

  @override
  Future<void> preload() async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void onPositionUpdate(void Function(Duration) callback) {}

  @override
  void onBufferUpdate(void Function(int percent) callback) {}

  @override
  void onPrepared(void Function(bool prepared) callback) {}
}
```

Register it:

```dart
YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
  platformEngines: {
    PlatformKey.android: (src) => MyCustomEngine(src),
    PlatformKey.ios:     (src) => MyCustomEngine(src),
  },
));
```

---

## TXPlayerEngine (Tencent Super Player)

`TXPlayerEngine` is a stub implementation for the Tencent `super_player` SDK. To enable it:

1. Add `super_player` to your `pubspec.yaml`
2. Initialize the license before `YuNiPlayerPlugin.initialize()`:

```dart
import 'package:yu_ni_player/engines/tx_player_engine.dart';

TXPlayerEngine.initLicense(
  'https://license.vod2.myqcloud.com/license/v2/xxx/v_cube.license',
  'your-license-key',
);
```

3. Register the engine:

```dart
YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
  platformEngines: {
    PlatformKey.ios:     (src) => TXPlayerEngine(src),
    PlatformKey.android: (src) => TXPlayerEngine(src),
    PlatformKey.macos:   (src) => VideoPlayerKitEngine(src),
    PlatformKey.windows: (src) => VideoPlayerKitEngine(src),
    PlatformKey.web:     (src) => VideoPlayerKitEngine(src),
  },
));
```

> **Note**: The `TXPlayerEngine` implementation requires the `super_player` package to be installed. The engine file contains the complete implementation template with all SDK calls documented.

---

## MediaKitEngine (Linux)

`MediaKitEngine` is a stub implementation for the `media_kit` SDK. To enable it:

1. Add `media_kit`, `media_kit_video`, and `media_kit_libs_video` to your `pubspec.yaml`
2. Register the engine:

```dart
import 'package:yu_ni_player/engines/media_kit_engine.dart';

YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
  platformEngines: {
    PlatformKey.linux: (src) => MediaKitEngine(src),
    // ... other platforms
  },
));
```

---

## API Reference

### `YuNiPlayer` widget

| Parameter | Type | Default | Description |
|---|---|---|---|
| `player` | `YuNiPlayerEngine` | required | Player engine instance |
| `backgroundColor` | `Color?` | `Colors.black` | Background color |
| `loadingBuilder` | `WidgetBuilder?` | null | Custom loading indicator |
| `errorBuilder` | `Widget Function(ctx, error)?` | null | Custom error widget |
| `showDefaultControls` | `bool` | `false` | Show built-in control bar |
| `controlsBuilder` | `YuNiControlsBuilder?` | null | Custom control bar builder |
| `aspectRatio` | `double?` | auto | Force aspect ratio |
| `onFullscreenChanged` | `void Function(bool)?` | null | Fullscreen state callback |
| `allowFullscreen` | `bool` | `true` | Enable fullscreen button |

### `YuNiPlayerEngine` methods

| Method | Description |
|---|---|
| `init({YuNiEngineConfig? config})` | Initialize and optionally auto-play |
| `play()` | Start/resume playback |
| `pause()` | Pause playback |
| `seek(double seconds, {bool? autoPlay})` | Seek to position |
| `setRate(double rate)` | Set playback speed [0.25, 4.0] |
| `setMute(bool mute)` | Mute/unmute |
| `setVolume(double volume)` | Set volume [0.0, 1.0] |
| `setLoop(bool loop)` | Enable/disable loop |
| `preload()` | Preload video |
| `release()` | Release native resources (keep instance for pool reuse) |
| `dispose()` | Release all resources permanently |
| `buildView()` | Get the video rendering widget |

### `YuNiEngineConfig`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `loop` | `bool` | `false` | Loop playback |
| `mute` | `bool` | `false` | Start muted |
| `autoPlay` | `bool` | `false` | Auto-play after init |
| `speed` | `double` | `1.0` | Playback speed [0.25, 4.0] |
| `hardwareAcceleration` | `bool` | `true` | Enable hardware decoding |
| `headers` | `Map<String, String>` | `{}` | Custom HTTP headers |

### `YuNiPlayerState`

```
idle → loading → paused ↔ playing → completed
                    ↕                    ↕
                  error ←──────────────────
playing ↔ buffering
```

| State | Description |
|---|---|
| `idle` | Initial state, not initialized |
| `loading` | Initializing / loading |
| `playing` | Playing |
| `paused` | Paused (ready to resume) |
| `completed` | Reached end of video |
| `error` | Playback error |
| `buffering` | Buffering (playback interrupted) |

### `YuNiVideoSource`

| Parameter | Type | Description |
|---|---|---|
| `id` | `String` | Unique identifier (used as pool key) |
| `url` | `String?` | Network URL (required if `file` is null) |
| `file` | `File?` | Local file (required if `url` is null) |
| `width` | `int?` | Video width hint (optional) |
| `height` | `int?` | Video height hint (optional) |
| `aspectRatio` | `double?` | Aspect ratio hint (optional) |
| `cover` | `String?` | Cover image URL or path (optional) |

### `YuNiPlayerPool`

| Method | Description |
|---|---|
| `acquire(source)` | Get or create a player for the given source |
| `release(source)` | Release a player back to the pool |
| `disposeAll()` | Dispose all active and recycled players |
| `configure({maxActiveCount, maxRecycledCount})` | Configure pool capacity |
| `currentPlayer` | Set to protect a player from LRU eviction |
| `activeCount` | Number of active players |
| `recycledCount` | Number of recycled players |

---

## Example App

The `example/` directory contains a full-featured demo app with 6 scenarios:

| Scenario | Description |
|---|---|
| Single player | Full control bar, fullscreen, error handling |
| TikTok-style | Vertical `PageView`, auto-play, seamless switching |
| Feed list | Scroll list + LRU pool + auto-play visible item |
| Hero animation | Thumbnail → fullscreen with Hero transition |
| Pool stress test | LRU eviction / reuse / currentPlayer protection |
| Lifecycle test | Background/foreground auto-pause/resume |

Run the example:

```bash
cd example
flutter run
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
