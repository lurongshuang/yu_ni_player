/// yu_ni_player_tx_player
///
/// TXPlayerEngine — 基于腾讯 super_player SDK 的引擎实现。
/// 支持 iOS 和 Android 平台，需要腾讯云播放器 License。
///
/// 使用方式：
/// ```dart
/// import 'package:yu_ni_player_tx_player/yu_ni_player_tx_player.dart';
///
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   TXPlayerEngine.initLicense(
///     'https://license.vod2.myqcloud.com/license/v2/xxx/v_cube.license',
///     'your-license-key',
///   );
///   YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
///     platformEngines: {
///       PlatformKey.ios:     (src) => TXPlayerEngine(src),
///       PlatformKey.android: (src) => TXPlayerEngine(src),
///     },
///   ));
///   runApp(const MyApp());
/// }
/// ```
library;

export 'src/tx_player_engine.dart';
