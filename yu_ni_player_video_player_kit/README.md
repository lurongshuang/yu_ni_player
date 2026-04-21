# yu_ni_player_video_player_kit

Flutter official `video_player` engine implementation for `yu_ni_player`.

This package provides a `VideoPlayerKitEngine` implementation for the `yu_ni_player` unified API, powered by the official Flutter `video_player` plugin.

## Support

- Primary engine for **macOS**, **Windows**, and **Web**.
- Fallback engine for **iOS** and **Android**.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  yu_ni_player_base: ^1.0.0
  yu_ni_player_video_player_kit: ^1.0.0
  video_player: ^2.11.1
  video_player_win: ^3.2.2
```

## Usage

Register the engine during initialization:

```dart
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

void main() {
  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.macos: (src) => VideoPlayerKitEngine(src),
      PlatformKey.windows: (src) => VideoPlayerKitEngine(src),
      PlatformKey.web: (src) => VideoPlayerKitEngine(src),
    },
  ));
  runApp(MyApp());
}
```

For more details, please refer to the main repository: [yu_ni_player](https://github.com/lurongshuang/yu_ni_player)
