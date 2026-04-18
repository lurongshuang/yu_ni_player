import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

import '../core/yu_ni_player_engine.dart';
import '../core/yu_ni_player_exception.dart';
import '../core/yu_ni_video_source.dart';
import 'platform_key.dart';
import 'yu_ni_player_registry.dart';

/// 播放器工厂（不可实例化）
///
/// 根据当前运行平台自动选择对应的引擎构造器，
/// 通过 [YuNiPlayerRegistry] 解析并创建 [YuNiPlayerEngine] 实例。
class YuNiPlayerFactory {
  // 私有构造函数，防止实例化
  YuNiPlayerFactory._();

  /// 返回当前平台对应的 [PlatformKey]。
  ///
  /// 判断顺序：`kIsWeb` → Android → iOS → macOS → Windows → Linux → defaultKey。
  /// 注意：`kIsWeb` 必须在 `Platform.*` 之前判断，因为 Web 平台不支持 `dart:io`。
  static String _currentPlatformKey() {
    if (kIsWeb) {
      return PlatformKey.web;
    } else if (Platform.isAndroid) {
      return PlatformKey.android;
    } else if (Platform.isIOS) {
      return PlatformKey.ios;
    } else if (Platform.isMacOS) {
      return PlatformKey.macos;
    } else if (Platform.isWindows) {
      return PlatformKey.windows;
    } else if (Platform.isLinux) {
      return PlatformKey.linux;
    } else {
      return PlatformKey.defaultKey;
    }
  }

  /// 根据当前平台和 [source] 创建对应的 [YuNiPlayerEngine]。
  ///
  /// 若当前平台没有注册对应引擎（含 fallback 到 `default`），
  /// 则抛出 [YuNiPlayerException]。
  static YuNiPlayerEngine create(YuNiVideoSource source) {
    final key = _currentPlatformKey();
    final builder = YuNiPlayerRegistry.instance.resolve(key);
    if (builder == null) {
      throw YuNiPlayerException(
        'No engine registered for platform "$key". '
        'Call YuNiPlayerPlugin.initialize() with a platformEngines map, '
        'or register a "default" engine via YuNiPlayerRegistry.',
      );
    }
    return builder(source);
  }
}
