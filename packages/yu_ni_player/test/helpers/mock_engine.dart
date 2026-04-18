import 'package:flutter/widgets.dart';
import 'package:yu_ni_player/src/core/yu_ni_player_engine.dart';
import 'package:yu_ni_player/src/core/yu_ni_player_state.dart';

/// 用于测试的 Mock 引擎实现。
///
/// 所有 `perform*` 方法和控制方法均为空实现，不依赖任何真实 SDK。
/// 供对象池测试（任务 4.3）和状态机测试（任务 10.x）使用。
class MockEngine extends YuNiPlayerEngine {
  MockEngine(super.source);

  // ── isPrepared ────────────────────────────────────────────────

  @override
  bool get isPrepared =>
      state != YuNiPlayerState.idle && state != YuNiPlayerState.error;

  // ── UI 渲染 ───────────────────────────────────────────────────

  @override
  Widget buildView() => const SizedBox();

  // ── perform* 空实现 ───────────────────────────────────────────

  @override
  Future<void> performInit() async {}

  @override
  Future<void> performPlay() async {}

  @override
  Future<void> performPause() async {}

  @override
  Future<void> performSeek(double seconds) async {}

  @override
  Future<void> performDispose() async {}

  @override
  Future<void> performRelease() async {}

  // ── 播放控制空实现 ────────────────────────────────────────────

  @override
  Future<void> setLoop(bool loop) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setMute(bool mute) async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> preload() async {}

  // ── 监听器空实现 ──────────────────────────────────────────────

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  // ── 回调注册空实现 ────────────────────────────────────────────

  @override
  void onPositionUpdate(void Function(Duration) callback) {}

  @override
  void onBufferUpdate(void Function(int percent) callback) {}

  @override
  void onPrepared(void Function(bool prepared) callback) {}
}
