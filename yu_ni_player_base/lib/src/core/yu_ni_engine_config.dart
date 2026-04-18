import 'package:flutter/foundation.dart';

/// 单次播放配置（不可变，提供 copyWith）
///
/// 用于控制循环、静音、自动播放、倍速、硬件加速及自定义请求头等参数。
/// [speed] 必须在 [0.25, 4.0] 范围内，否则构造时抛出 [AssertionError]。
class YuNiEngineConfig {
  const YuNiEngineConfig({
    this.loop = false,
    this.mute = false,
    this.autoPlay = false,
    this.speed = 1.0,
    this.hardwareAcceleration = true,
    this.headers = const {},
  }) : assert(
          speed >= 0.25 && speed <= 4.0,
          'speed must be in range [0.25, 4.0], got $speed',
        );

  /// 是否循环播放，默认 false
  final bool loop;

  /// 是否静音，默认 false
  final bool mute;

  /// 是否自动播放，默认 false
  final bool autoPlay;

  /// 播放速度，范围 [0.25, 4.0]，默认 1.0
  final double speed;

  /// 是否启用硬件加速，默认 true
  final bool hardwareAcceleration;

  /// 自定义请求头，默认空 Map
  final Map<String, String> headers;

  /// 返回仅修改指定字段的新实例，未指定字段保持原值
  YuNiEngineConfig copyWith({
    bool? loop,
    bool? mute,
    bool? autoPlay,
    double? speed,
    bool? hardwareAcceleration,
    Map<String, String>? headers,
  }) {
    return YuNiEngineConfig(
      loop: loop ?? this.loop,
      mute: mute ?? this.mute,
      autoPlay: autoPlay ?? this.autoPlay,
      speed: speed ?? this.speed,
      hardwareAcceleration: hardwareAcceleration ?? this.hardwareAcceleration,
      headers: headers ?? this.headers,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is YuNiEngineConfig &&
      loop == other.loop &&
      mute == other.mute &&
      autoPlay == other.autoPlay &&
      speed == other.speed &&
      hardwareAcceleration == other.hardwareAcceleration &&
      mapEquals(headers, other.headers);

  @override
  int get hashCode => Object.hash(
        loop,
        mute,
        autoPlay,
        speed,
        hardwareAcceleration,
        Object.hashAll(headers.entries.toList()),
      );

  @override
  String toString() =>
      'YuNiEngineConfig(loop: $loop, mute: $mute, autoPlay: $autoPlay, '
      'speed: $speed, hardwareAcceleration: $hardwareAcceleration, '
      'headers: $headers)';
}
