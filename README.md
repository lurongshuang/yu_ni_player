# yu_ni_player

A unified Flutter video player monorepo with **multi-engine support**. Pick only the engine you need — no unnecessary SDK dependencies.

[![Flutter](https://img.shields.io/badge/Flutter-≥3.10.0-blue)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-≥3.0.0-blue)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Packages

| Package | Description | Dependencies |
|---|---|---|
| [`yu_ni_player`](packages/yu_ni_player) | Base library — core API, LRU pool, fullscreen widget, controls | `flutter` only |
| [`yu_ni_player_video_player_kit`](packages/yu_ni_player_video_player_kit) | VideoPlayerKitEngine — Flutter official `video_player` | `video_player ^2.9.2` |
| [`yu_ni_player_tx_player`](packages/yu_ni_player_tx_player) | TXPlayerEngine — Tencent `super_player` (iOS/Android) | `super_player ^13.1.0` |
| [`yu_ni_player_media_kit`](packages/yu_ni_player_media_kit) | MediaKitEngine — open source `media_kit` (all platforms) | `media_kit ^1.2.6` |

---

## Architecture

```
yu_ni_player/                              ← GitHub repo root (monorepo)
├── packages/
│   ├── yu_ni_player/                      ← Base library (zero player SDK deps)
│   │   └── lib/src/
│   │       ├── core/                      ← YuNiPlayerEngine, YuNiPlayerState, etc.
│   │       ├── pool/                      ← YuNiPlayerPool (LRU)
│   │       ├── registry/                  ← YuNiPlayerRegistry, YuNiPlayerFactory
│   │       ├── plugin/                    ← YuNiPlayerPlugin, YuNiPlayerConfig
│   │       └── ui/                        ← YuNiPlayer widget, YuNiDefaultControls
│   │
│   ├── yu_ni_player_video_player_kit/     ← VideoPlayerKitEngine
│   ├── yu_ni_player_tx_player/            ← TXPlayerEngine
│   └── yu_ni_player_media_kit/            ← MediaKitEngine
│
├── example/                               ← Example app (uses all engines)
├── melos.yaml                             ← Melos monorepo config
└── pubspec.yaml                           ← Workspace root
```

---

## Installation

Add only the engine(s) you need:

```yaml
dependencies:
  # Base library (always required)
  yu_ni_player:
    git:
      url: https://github.com/lurongshuang/yu_ni_player.git
      path: packages/yu_ni_player

  # Pick one or more engines:

  # Option A: video_player (free, all platforms)
  yu_ni_player_video_player_kit:
    git:
      url: https://github.com/lurongshuang/yu_ni_player.git
      path: packages/yu_ni_player_video_player_kit

  # Option B: Tencent super_player (iOS/Android, requires license)
  yu_ni_player_tx_player:
    git:
      url: https://github.com/lurongshuang/yu_ni_player.git
      path: packages/yu_ni_player_tx_player

  # Option C: media_kit (open source, all platforms)
  yu_ni_player_media_kit:
    git:
      url: https://github.com/lurongshuang/yu_ni_player.git
      path: packages/yu_ni_player_media_kit
```

---

## Quick Start

### Using VideoPlayerKitEngine (recommended for most apps)

```dart
import 'package:yu_ni_player/yu_ni_player.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.ios:        (src) => VideoPlayerKitEngine(src),
      PlatformKey.android:    (src) => VideoPlayerKitEngine(src),
      PlatformKey.macos:      (src) => VideoPlayerKitEngine(src),
      PlatformKey.windows:    (src) => VideoPlayerKitEngine(src),
      PlatformKey.web:        (src) => VideoPlayerKitEngine(src),
      PlatformKey.defaultKey: (src) => VideoPlayerKitEngine(src),
    },
  ));

  runApp(const MyApp());
}
```

### Using TXPlayerEngine (iOS/Android with Tencent license)

```dart
import 'package:yu_ni_player/yu_ni_player.dart';
import 'package:yu_ni_player_tx_player/yu_ni_player_tx_player.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  TXPlayerEngine.initLicense(
    'https://license.vod2.myqcloud.com/license/v2/xxx/v_cube.license',
    'your-license-key',
  );

  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.ios:     (src) => TXPlayerEngine(src),
      PlatformKey.android: (src) => TXPlayerEngine(src),
      PlatformKey.macos:   (src) => VideoPlayerKitEngine(src),
      PlatformKey.windows: (src) => VideoPlayerKitEngine(src),
      PlatformKey.web:     (src) => VideoPlayerKitEngine(src),
    },
  ));

  runApp(const MyApp());
}
```

### Using MediaKitEngine (open source, all platforms)

```dart
import 'package:yu_ni_player/yu_ni_player.dart';
import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKitEngine.initLicense(); // required before runApp

  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.defaultKey: (src) => MediaKitEngine(src),
    },
  ));

  runApp(const MyApp());
}
```

---

## Widget Usage

```dart
class VideoPage extends StatefulWidget { ... }

class _VideoPageState extends State<VideoPage> {
  late YuNiPlayerEngine _player;

  @override
  void initState() {
    super.initState();
    final source = YuNiVideoSource(id: 'video_1', url: 'https://example.com/video.mp4');
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
      showDefaultControls: true,
      allowFullscreen: true,
    );
  }
}
```

---

## Development

This repo uses [Melos](https://melos.invertase.dev/) for monorepo management.

```bash
# Install melos
dart pub global activate melos

# Bootstrap all packages
melos bootstrap

# Run flutter pub get on all packages
melos run pub_get

# Analyze all packages
melos run analyze

# Run tests
melos run test
```

---

## License

MIT License. See [LICENSE](LICENSE) for details.
