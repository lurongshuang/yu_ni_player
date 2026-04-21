# yu_ni_player_media_kit

`media_kit` engine implementation for `yu_ni_player`.

This package provides a `MediaKitEngine` implementation for the `yu_ni_player` unified API, enabling high-performance video playback powered by `media_kit`.

## Support

- Primary engine for **Linux**.
- Robust cross-platform support.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  yu_ni_player_base: ^1.0.0
  yu_ni_player_media_kit: ^1.0.0
  media_kit: ^1.2.6
  media_kit_video: ^2.0.1
  media_kit_libs_video: ^1.0.7
```

## Usage

Register the engine during initialization:

```dart
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';

void main() {
  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.linux: (src) => MediaKitEngine(src),
    },
  ));
  runApp(MyApp());
}
```

For more details, please refer to the main repository: [yu_ni_player](https://github.com/lurongshuang/yu_ni_player)
