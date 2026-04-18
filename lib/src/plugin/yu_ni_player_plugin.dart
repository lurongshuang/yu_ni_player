import 'package:flutter/foundation.dart';

import '../pool/yu_ni_player_pool.dart';
import '../registry/yu_ni_player_registry.dart';
import 'yu_ni_player_config.dart';

/// 插件入口，负责全局初始化
///
/// 在 `main()` 中调用一次 [initialize]，完成平台-引擎注册和对象池配置。
///
/// ```dart
/// void main() {
///   YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
///     platformEngines: {
///       PlatformKey.ios:     (src) => TXPlayerEngine(src),
///       PlatformKey.android: (src) => TXPlayerEngine(src),
///       PlatformKey.macos:   (src) => VideoPlayerKitEngine(src),
///     },
///   ));
///   runApp(MyApp());
/// }
/// ```
class YuNiPlayerPlugin {
  // 私有构造函数，防止实例化
  YuNiPlayerPlugin._();

  static bool _initialized = false;

  /// 初始化插件（应在 main() 中调用一次）。
  ///
  /// 若重复调用，会打印警告并应用新配置（覆盖旧配置）。
  static void initialize(YuNiPlayerConfig config) {
    if (_initialized) {
      debugPrint(
        '[YuNiPlayer] Warning: initialize() called more than once. '
        'Applying new configuration.',
      );
    }
    _initialized = true;

    // 注册平台引擎
    YuNiPlayerRegistry.instance.registerAll(config.platformEngines);

    // 配置对象池
    YuNiPlayerPool.instance.configure(
      maxActiveCount: config.maxActiveCount,
      maxRecycledCount: config.maxRecycledCount,
    );
  }

  /// 是否已初始化（测试用）
  static bool get isInitialized => _initialized;

  /// 重置初始化状态（仅供测试使用）
  @visibleForTesting
  static void reset() {
    _initialized = false;
  }
}
