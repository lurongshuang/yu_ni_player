import 'package:flutter/widgets.dart';

import 'yu_ni_engine_config.dart';
export 'yu_ni_player_state.dart';
import 'yu_ni_player_state.dart';
import 'yu_ni_video_data.dart';
import 'yu_ni_video_source.dart';

/// 引擎构造函数类型
///
/// 用于 [YuNiPlayerRegistry] 中注册平台对应的引擎构造器。
typedef EngineBuilder = YuNiPlayerEngine Function(YuNiVideoSource source);

/// 播放器引擎抽象基类
///
/// 所有播放器内核必须继承此类并实现所有 `perform*` 抽象方法。
/// 公开 API（[init]、[play]、[pause]、[seek]、[dispose]、[release]、[reset]）
/// 采用模板方法模式，在基类中处理通用逻辑（状态守卫、状态转换），
/// 具体实现委托给子类的 `perform*` 方法。
abstract class YuNiPlayerEngine {
  YuNiPlayerEngine(this.videoSource);

  // ── 数据 ──────────────────────────────────────────────────────

  /// 当前视频源（可变，用于对象池更新 source）
  YuNiVideoSource videoSource;

  /// 当前播放配置
  YuNiEngineConfig config = const YuNiEngineConfig();

  /// 播放器运行时数据
  final YuNiVideoData videoData = YuNiVideoData();

  // ── 状态通知 ──────────────────────────────────────────────────

  /// 播放器状态通知器，供 UI 层响应式监听
  final ValueNotifier<YuNiPlayerState> stateNotifier =
      ValueNotifier(YuNiPlayerState.idle);

  /// 底层 native 播放器实例重建时此值变化，UI 层监听后重建 View
  final ValueNotifier<int> instanceCode = ValueNotifier(0);

  bool _disposed = false;

  // ── 状态 getter ───────────────────────────────────────────────

  /// 当前播放器状态
  YuNiPlayerState get state => stateNotifier.value;

  /// 是否正在播放
  bool get isPlaying => state == YuNiPlayerState.playing;

  /// 是否处于错误状态
  bool get isError => state == YuNiPlayerState.error;

  /// 是否已销毁
  bool get isDisposed => _disposed;

  /// 底层 native 播放器是否已就绪（由子类实现，依赖底层 SDK 状态）
  bool get isPrepared;

  // ── 模板方法：公开 API ─────────────────────────────────────────

  /// 初始化播放器。
  ///
  /// 状态转换：idle → loading → paused（或 playing 若 [YuNiEngineConfig.autoPlay] 为 true）
  ///
  /// 若传入 [config] 则更新当前配置。初始化失败时状态转为 [YuNiPlayerState.error]
  /// 并将错误存入 [YuNiVideoData.lastError]。
  Future<void> init({YuNiEngineConfig? config}) async {
    if (_disposed) return;
    if (config != null) this.config = config;
    updateState(YuNiPlayerState.loading);
    try {
      await performInit();
    } catch (e) {
      videoData.lastError = e;
      updateState(YuNiPlayerState.error);
      return;
    }
    await setLoop(this.config.loop);
    await setMute(this.config.mute);
    await setRate(this.config.speed);
    if (this.config.autoPlay) {
      await play();
    } else {
      updateState(YuNiPlayerState.paused);
    }
  }

  /// 开始播放。
  ///
  /// 若尚未初始化（[isPrepared] 为 false）则先调用 [init]。
  /// 成功后状态转为 [YuNiPlayerState.playing]。
  Future<void> play() async {
    if (_disposed) return;
    if (!isPrepared) await init();
    await performPlay();
    updateState(YuNiPlayerState.playing);
  }

  /// 暂停播放。
  ///
  /// 成功后状态转为 [YuNiPlayerState.paused]。
  Future<void> pause() async {
    if (_disposed) return;
    await performPause();
    updateState(YuNiPlayerState.paused);
  }

  /// Seek 到指定位置（秒）。
  ///
  /// [seconds] 会被 clamp 到 `[0, videoData.duration.inSeconds]`。
  /// [autoPlay] 为 null 时保持 seek 前的播放/暂停状态；
  /// 为 true 时 seek 后播放；为 false 时 seek 后暂停。
  Future<void> seek(double seconds, {bool? autoPlay}) async {
    if (_disposed) return;
    final maxSeconds = videoData.duration.inSeconds.toDouble();
    final clamped = seconds.clamp(0.0, maxSeconds);
    final wasPlaying = isPlaying;
    await performSeek(clamped);
    final shouldPlay = autoPlay ?? wasPlaying;
    if (shouldPlay) {
      await performPlay();
      updateState(YuNiPlayerState.playing);
    } else {
      await performPause();
      updateState(YuNiPlayerState.paused);
    }
  }

  /// 销毁播放器，释放所有 native 资源。
  ///
  /// 调用后 [isDisposed] 为 true，后续所有控制方法均直接 return。
  /// 此方法幂等，多次调用不会抛出异常。
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await performDispose();
    // 在 performDispose 完成后再 dispose notifier，
    // 避免异步回调在 dispose 期间写入已销毁的 notifier
    stateNotifier.dispose();
    instanceCode.dispose();
  }

  /// 释放 native 资源但保留实例（可重新 [init]，用于对象池回收）。
  ///
  /// 调用后状态重置为 [YuNiPlayerState.idle]，[videoData] 被重置。
  /// 若已 dispose 则直接 return，不执行任何操作。
  Future<void> release() async {
    if (_disposed) return;
    await performRelease();
    videoData.reset();
    updateState(YuNiPlayerState.idle);
  }

  /// 重置播放器：等同于 [release] + 重置 [videoData] + 状态回到 idle。
  Future<void> reset() async {
    if (_disposed) return;
    await release();
    videoData.reset();
    updateState(YuNiPlayerState.idle);
  }

  // ── 播放控制封装（模板方法） ──────────────────────────────────

  /// 设置是否循环播放。同步更新 [config]。
  Future<void> setLoop(bool loop) async {
    if (_disposed) return;
    await performSetLoop(loop);
    config = config.copyWith(loop: loop);
  }

  /// 设置音量（0.0 ~ 1.0）。
  Future<void> setVolume(double volume) async {
    if (_disposed) return;
    await performSetVolume(volume);
  }

  /// 设置是否静音。同步更新 [config]。
  Future<void> setMute(bool mute) async {
    if (_disposed) return;
    await performSetMute(mute);
    config = config.copyWith(mute: mute);
  }

  /// 设置播放速率（[0.25, 4.0]）。同步更新 [config]。
  Future<void> setRate(double rate) async {
    if (_disposed) return;
    await performSetRate(rate);
    config = config.copyWith(speed: rate);
  }

  // ── 抽象方法：子类实现具体逻辑 ────────────────────────────────

  /// 子类实现：初始化底层 SDK 并开始加载视频
  @protected
  Future<void> performInit();

  /// 子类实现：开始/恢复播放
  @protected
  Future<void> performPlay();

  /// 子类实现：暂停播放
  @protected
  Future<void> performPause();

  /// 子类实现：Seek 到指定秒数（已 clamp）
  @protected
  Future<void> performSeek(double seconds);

  /// 子类实现：销毁底层 SDK 资源
  @protected
  Future<void> performDispose();

  /// 子类实现：释放 native 资源但保留实例（用于对象池回收）
  @protected
  Future<void> performRelease();

  // ── 播放控制子类实现（原 setXXX 方法的基础） ─────────────────

  /// 子类具体实现：设置是否循环播放
  @protected
  Future<void> performSetLoop(bool loop);

  /// 子类具体实现：设置音量（0.0 ~ 1.0）
  @protected
  Future<void> performSetVolume(double volume);

  /// 子类具体实现：设置是否静音
  @protected
  Future<void> performSetMute(bool mute);

  /// 子类具体实现：设置播放速率（[0.25, 4.0]）
  @protected
  Future<void> performSetRate(double rate);

  /// 预加视频资源（可选实现）
  Future<void> preload();

  // ── UI 渲染（抽象，子类实现）─────────────────────────────────

  /// 返回平台特定的视频渲染 Widget。
  ///
  /// 每个引擎自己提供渲染 Widget，消除 UI 层的 if-else 判断。
  Widget buildView();

  // ── 监听器（抽象，子类实现）──────────────────────────────────

  /// 添加状态变化监听器（代理给底层 ChangeNotifier）
  void addListener(VoidCallback listener);

  /// 移除状态变化监听器
  void removeListener(VoidCallback listener);

  // ── 回调注册（抽象，子类实现）────────────────────────────────

  /// 注册播放进度回调
  void onPositionUpdate(void Function(Duration) callback);

  /// 注册缓冲进度回调（percent: 0–100）
  void onBufferUpdate(void Function(int percent) callback);

  /// 注册就绪状态回调
  void onPrepared(void Function(bool prepared) callback);

  // ── 内部状态更新 ──────────────────────────────────────────────

  /// 更新播放器状态。
  ///
  /// 若已销毁或新状态与当前状态相同则直接 return（避免无效通知）。
  @protected
  void updateState(YuNiPlayerState newState) {
    if (_disposed) return;
    if (stateNotifier.value != newState) {
      stateNotifier.value = newState;
    }
  }
}
