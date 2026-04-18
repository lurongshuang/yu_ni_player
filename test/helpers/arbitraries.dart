import 'package:glados/glados.dart';
import 'package:yu_ni_player/src/core/yu_ni_engine_config.dart';

/// 自定义 Arbitrary 扩展，为 YuNiEngineConfig 属性测试提供生成器
extension YuNiArbitraries on Any {
  /// 生成 [0.25, 4.0] 范围内的合法播放速度
  Generator<double> get validSpeed => doubleInRange(0.25, 4.0);

  /// 生成越界播放速度：< 0.25 或 > 4.0
  /// 使用两个有限区间，避免 NaN/Infinity
  Generator<double> get invalidSpeed {
    // 在两个越界区间中随机选择：[-10.0, 0.25) 或 (4.0, 14.0]
    return either(
      doubleInRange(-10.0, 0.249999),
      doubleInRange(4.000001, 14.0),
    );
  }

  /// 生成随机 YuNiEngineConfig 实例（speed 使用 validSpeed）
  Generator<YuNiEngineConfig> get engineConfig {
    return combine5(
      any.bool,
      any.bool,
      any.bool,
      validSpeed,
      any.bool,
      (loop, mute, autoPlay, speed, hardwareAcceleration) => YuNiEngineConfig(
        loop: loop,
        mute: mute,
        autoPlay: autoPlay,
        speed: speed,
        hardwareAcceleration: hardwareAcceleration,
        headers: const {},
      ),
    );
  }
}
