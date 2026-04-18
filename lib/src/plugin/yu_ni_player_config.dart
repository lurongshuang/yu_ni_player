import '../core/yu_ni_player_engine.dart';

/// 插件级全局配置
///
/// 在 [YuNiPlayerPlugin.initialize] 中传入，用于配置平台-引擎映射和对象池容量。
class YuNiPlayerConfig {
  const YuNiPlayerConfig({
    this.platformEngines = const {},
    this.maxActiveCount = 3,
    this.maxRecycledCount = 2,
  });

  /// 平台 → 引擎构造器映射
  ///
  /// key 使用 [PlatformKey] 中的常量，value 为对应的 [EngineBuilder]。
  final Map<String, EngineBuilder> platformEngines;

  /// 活跃播放器最大数量（LRU 淘汰阈值），默认 3
  final int maxActiveCount;

  /// 回收池最大容量，默认 2
  final int maxRecycledCount;
}
