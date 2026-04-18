/// yu_ni_player_video_player_kit
///
/// VideoPlayerKitEngine — 基于 Flutter 官方 video_player 包的引擎实现。
/// 支持 iOS、Android、macOS、Windows、Web 平台，无需额外许可证。
///
/// 使用方式：
/// ```dart
/// import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';
///
/// YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
///   platformEngines: {
///     PlatformKey.ios:        (src) => VideoPlayerKitEngine(src),
///     PlatformKey.android:    (src) => VideoPlayerKitEngine(src),
///     PlatformKey.macos:      (src) => VideoPlayerKitEngine(src),
///     PlatformKey.windows:    (src) => VideoPlayerKitEngine(src),
///     PlatformKey.web:        (src) => VideoPlayerKitEngine(src),
///     PlatformKey.defaultKey: (src) => VideoPlayerKitEngine(src),
///   },
/// ));
/// ```
library;

export 'src/video_player_kit_engine.dart';
