# yu_ni_player_tx_player

Tencent `super_player` engine implementation for `yu_ni_player`.

This package provides a `TXPlayerEngine` implementation for the `yu_ni_player` unified API, enabling high-performance video playback on mobile platforms (iOS & Android) powered by Tencent Super Player SDK.

## Support

- Primary engine for **iOS** and **Android**.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  yu_ni_player_base: ^1.0.0
  yu_ni_player_tx_player: ^1.0.0
  super_player: ^13.1.0
```

## Usage

Register the engine during initialization:

```dart
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_tx_player/yu_ni_player_tx_player.dart';

void main() {
  // Initialize License (Required for Tencent Player)
  TXPlayerEngine.initLicense(
    'https://your-license-url',
    'your-license-key',
  );

  YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
    platformEngines: {
      PlatformKey.ios: (src) => TXPlayerEngine(src),
      PlatformKey.android: (src) => TXPlayerEngine(src),
    },
  ));
  runApp(MyApp());
}
```

For more details, please refer to the main repository: [yu_ni_player](https://github.com/lurongshuang/yu_ni_player)
