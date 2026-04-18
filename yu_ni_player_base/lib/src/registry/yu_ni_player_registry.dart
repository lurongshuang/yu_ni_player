import '../core/yu_ni_player_engine.dart';
import 'platform_key.dart';

/// 引擎注册表（单例）
///
/// 维护平台 key 到 [EngineBuilder] 的映射。
/// 通过 [register] 或 [registerAll] 注册引擎构造器，
/// 通过 [resolve] 按平台 key 查找对应构造器（含 fallback 到 [PlatformKey.defaultKey]）。
class YuNiPlayerRegistry {
  YuNiPlayerRegistry._();

  /// 全局单例
  static final YuNiPlayerRegistry instance = YuNiPlayerRegistry._();

  final Map<String, EngineBuilder> _builders = {};

  /// 注册单个平台引擎构造器。
  ///
  /// 若 [platformKey] 已存在，则覆盖原有映射。
  void register(String platformKey, EngineBuilder builder) {
    _builders[platformKey] = builder;
  }

  /// 批量注册平台引擎构造器。
  ///
  /// 对 [builders] 中每个条目调用 [register]，已有 key 会被覆盖。
  void registerAll(Map<String, EngineBuilder> builders) {
    builders.forEach(register);
  }

  /// 按平台 key 解析引擎构造器。
  ///
  /// 先查找 [platformKey] 对应的构造器；若不存在，则 fallback 到
  /// [PlatformKey.defaultKey] 对应的构造器；若仍不存在则返回 null。
  EngineBuilder? resolve(String platformKey) {
    return _builders[platformKey] ?? _builders[PlatformKey.defaultKey];
  }

  /// 清空所有注册（仅供测试使用）。
  void clear() {
    _builders.clear();
  }
}
