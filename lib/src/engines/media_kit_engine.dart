// ignore_for_file: undefined_identifier, undefined_class, undefined_prefixed_name, unused_field, unused_element
//
// MediaKitEngine — media_kit 引擎（Linux，可选）
//
// 此文件依赖 `media_kit` 和 `media_kit_video` 包，需在宿主项目的 pubspec.yaml 中添加：
//
//   dependencies:
//     media_kit: ^x.x.x
//     media_kit_video: ^x.x.x
//     media_kit_libs_video: ^x.x.x
//
// 在宿主项目中注册引擎：
//
//   YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
//     platformEngines: {
//       PlatformKey.linux: (src) => MediaKitEngine(src),
//     },
//   ));

import 'package:flutter/widgets.dart';

import '../core/yu_ni_player_engine.dart';
import '../core/yu_ni_player_state.dart';

/// media_kit 引擎，适用于 Linux 平台（可选）。
///
/// 依赖 `media_kit` SDK（`Player`、`VideoController`、`Video` 等）。
/// 使用前需调用 [initLicense] 完成 SDK 初始化。
///
/// **注意**：此引擎需要在宿主项目的 `pubspec.yaml` 中声明 `media_kit` 相关依赖。
class MediaKitEngine extends YuNiPlayerEngine {
  MediaKitEngine(super.source);

  // ── SDK 对象（dynamic 避免编译错误）──────────────────────────
  dynamic _player;
  dynamic _videoController;

  // ── 回调 ──────────────────────────────────────────────────────
  void Function(Duration)? _onPositionUpdateCallback;
  void Function(int)? _onBufferUpdateCallback;
  void Function(bool)? _onPreparedCallback;

  // ── 监听器列表 ────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── 静态初始化 ────────────────────────────────────────────────

  /// 初始化 media_kit SDK。
  ///
  /// 应在 [YuNiPlayerPlugin.initialize] 之前调用一次。
  static void initLicense() {
    // TODO: requires media_kit SDK
    // MediaKit.ensureInitialized();
  }

  // ── isPrepared ────────────────────────────────────────────────

  @override
  bool get isPrepared {
    if (_player == null) return false;
    // TODO: requires media_kit SDK
    // return _player.state.playing || _player.state.completed;
    return state != YuNiPlayerState.idle && state != YuNiPlayerState.error;
  }

  // ── performInit ───────────────────────────────────────────────

  @override
  Future<void> performInit() async {
    // TODO: requires media_kit SDK
    // _player = Player();
    // _videoController = VideoController(_player);
    instanceCode.value = identityHashCode(this);

    // final media = videoSource.file != null
    //     ? Media(videoSource.file!.path)
    //     : Media(videoSource.url!);
    // await _player.open(media, play: false);
  }

  // ── performPlay ───────────────────────────────────────────────

  @override
  Future<void> performPlay() async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.play();
  }

  // ── performPause ──────────────────────────────────────────────

  @override
  Future<void> performPause() async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.pause();
  }

  // ── performSeek ───────────────────────────────────────────────

  @override
  Future<void> performSeek(double seconds) async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.seek(Duration(seconds: seconds.toInt()));
  }

  // ── performDispose ────────────────────────────────────────────

  @override
  Future<void> performDispose() async {
    if (_player != null) {
      // TODO: requires media_kit SDK
      // await _player.dispose();
      _player = null;
      _videoController = null;
    }
    _listeners.clear();
  }

  // ── performRelease ────────────────────────────────────────────

  @override
  Future<void> performRelease() async {
    if (_player != null) {
      // TODO: requires media_kit SDK
      // await _player.dispose();
      _player = null;
      _videoController = null;
    }
    // 重建 player 和 videoController
    // TODO: requires media_kit SDK
    // _player = Player();
    // _videoController = VideoController(_player);
    instanceCode.value = identityHashCode(this) ^ DateTime.now().millisecondsSinceEpoch;
    _onPreparedCallback?.call(false);
  }

  // ── buildView ─────────────────────────────────────────────────

  @override
  Widget buildView() {
    // TODO: requires media_kit SDK
    // return Video(controller: _videoController);
    return const SizedBox.shrink(); // placeholder until media_kit is available
  }

  // ── 播放控制 ──────────────────────────────────────────────────

  @override
  Future<void> setLoop(bool loop) async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.setPlaylistMode(loop ? PlaylistMode.loop : PlaylistMode.none);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.setVolume(volume * 100);
  }

  @override
  Future<void> setMute(bool mute) async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.setVolume(mute ? 0.0 : 100.0);
  }

  @override
  Future<void> setRate(double rate) async {
    if (_player == null) return;
    // TODO: requires media_kit SDK
    // await _player.setRate(rate);
  }

  @override
  Future<void> preload() async {
    // media_kit 通过 open() 触发预加载，此处为空实现
  }

  // ── 监听器 ────────────────────────────────────────────────────

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // ── 回调注册 ──────────────────────────────────────────────────

  @override
  void onPositionUpdate(void Function(Duration) callback) {
    _onPositionUpdateCallback = callback;
  }

  @override
  void onBufferUpdate(void Function(int percent) callback) {
    _onBufferUpdateCallback = callback;
  }

  @override
  void onPrepared(void Function(bool prepared) callback) {
    _onPreparedCallback = callback;
  }
}
