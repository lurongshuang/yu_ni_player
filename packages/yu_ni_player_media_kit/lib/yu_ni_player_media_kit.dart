/// yu_ni_player_media_kit
///
/// MediaKitEngine — 基于 media_kit 的引擎实现（开源，全平台）。
/// 支持 Android、iOS、macOS、Windows、Linux、Web。
///
/// 使用方式：
/// ```dart
/// import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';
///
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   MediaKitEngine.initLicense(); // 必须在 runApp 之前调用
///   YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
///     platformEngines: {
///       PlatformKey.linux:      (src) => MediaKitEngine(src),
///       PlatformKey.defaultKey: (src) => MediaKitEngine(src),
///     },
///   ));
///   runApp(const MyApp());
/// }
/// ```
library;

export 'src/media_kit_engine.dart';
