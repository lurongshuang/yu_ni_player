// ignore_for_file: undefined_identifier, undefined_class, undefined_prefixed_name, unused_field, unused_element
//
// TXPlayerEngine — 腾讯超级播放器引擎（iOS / Android）
//
// 此文件依赖 `super_player` 包，需在宿主项目的 pubspec.yaml 中添加：
//
//   dependencies:
//     super_player: ^x.x.x
//
// 在宿主项目中注册引擎：
//
//   YuNiPlayerPlugin.initialize(YuNiPlayerConfig(
//     platformEngines: {
//       PlatformKey.ios:     (src) => TXPlayerEngine(src),
//       PlatformKey.android: (src) => TXPlayerEngine(src),
//     },
//   ));

import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';

import '../core/yu_ni_player_engine.dart';
import '../core/yu_ni_player_state.dart';

/// 腾讯超级播放器引擎，适用于 iOS 和 Android 平台。
///
/// 依赖 `super_player` SDK（`TXVodPlayerController`、`TXPlayerVideo` 等）。
/// 使用前需调用 [initLicense] 完成 SDK 授权初始化。
///
/// **注意**：此引擎需要在宿主项目的 `pubspec.yaml` 中声明 `super_player` 依赖。
class TXPlayerEngine extends YuNiPlayerEngine {
  TXPlayerEngine(super.source);

  // ── SDK 控制器（dynamic 避免编译错误，运行时为 TXVodPlayerController）──
  dynamic _controller;

  // ── 回调 ──────────────────────────────────────────────────────
  void Function(Duration)? _onPositionUpdateCallback;
  void Function(int)? _onBufferUpdateCallback;
  void Function(bool)? _onPreparedCallback;

  // ── 监听器列表 ────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── 静态初始化 ────────────────────────────────────────────────

  /// 初始化腾讯播放器 SDK 许可证。
  ///
  /// 应在 [YuNiPlayerPlugin.initialize] 之前调用一次。
  /// 仅在 iOS 和 Android 平台上生效。
  ///
  /// ```dart
  /// TXPlayerEngine.initLicense(
  ///   'https://license.vod2.myqcloud.com/license/v2/xxx/v_cube.license',
  ///   'your-license-key',
  /// );
  /// ```
  static void initLicense(String licenseUrl, String licenseKey) {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    // TODO: requires super_player SDK
    // SuperPlayerPlugin.setGlobalLicense(licenseUrl, licenseKey);
    // SuperPlayerPlugin.setGlobalMaxCacheSize(200);
    // SuperPlayerPlugin.setGlobalCacheFolderPath('videos');
  }

  // ── isPrepared ────────────────────────────────────────────────

  @override
  bool get isPrepared {
    if (_controller == null) return false;
    // TODO: requires super_player SDK
    // final s = _controller.playState;
    // return s != TXPlayerState.failed &&
    //     s != TXPlayerState.disposed &&
    //     s != TXPlayerState.stopped;
    return state != YuNiPlayerState.idle && state != YuNiPlayerState.error;
  }

  // ── performInit ───────────────────────────────────────────────

  @override
  Future<void> performInit() async {
    // TODO: requires super_player SDK
    // _controller = TXVodPlayerController();
    // _controller.onPlayerEventBroadcast.listen(_onPlayerEvent);
    // instanceCode.value = _controller.hashCode;
    //
    // final txConfig = FTXVodPlayConfig()..headers = config.headers;
    // await _controller.setConfig(txConfig);
    // await _controller.initialize();
    // _controller.setRenderMode(FTXPlayerRenderMode.ADJUST_RESOLUTION);
    // await _controller.setAutoPlay(isAutoPlay: false);
    // await _controller.enableHardwareDecode(config.hardwareAcceleration);
    // await _controller.startVodPlay(_resolveUrl());
    instanceCode.value = identityHashCode(this);
  }

  // ── performPlay ───────────────────────────────────────────────

  @override
  Future<void> performPlay() async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // await _controller.resume();
  }

  // ── performPause ──────────────────────────────────────────────

  @override
  Future<void> performPause() async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // await _controller.pause();
  }

  // ── performSeek ───────────────────────────────────────────────

  @override
  Future<void> performSeek(double seconds) async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // _controller.seek(seconds.toInt());
  }

  // ── performDispose ────────────────────────────────────────────

  @override
  Future<void> performDispose() async {
    if (_controller != null) {
      // TODO: requires super_player SDK
      // await _controller.dispose();
      _controller = null;
    }
    _listeners.clear();
    // instanceCode 和 stateNotifier 由基类 dispose() 负责 dispose
  }

  // ── performRelease ────────────────────────────────────────────

  /// 释放 native 资源并重建控制器（用于对象池回收后复用）。
  ///
  /// 重建后 [instanceCode] 变化，UI 层会重建 View。
  @override
  Future<void> performRelease() async {
    if (_controller != null) {
      // TODO: requires super_player SDK
      // await _controller.dispose();
      _controller = null;
    }
    // 重建控制器，触发 UI 重建
    // TODO: requires super_player SDK
    // _controller = TXVodPlayerController();
    // _controller.onPlayerEventBroadcast.listen(_onPlayerEvent);
    // instanceCode.value = _controller.hashCode;
    instanceCode.value = identityHashCode(this) ^ DateTime.now().millisecondsSinceEpoch;
    _onPreparedCallback?.call(false);
  }

  // ── buildView ─────────────────────────────────────────────────

  @override
  Widget buildView() {
    // TODO: requires super_player SDK
    // return TXPlayerVideo(
    //   androidRenderType: FTXAndroidRenderViewType.TEXTURE_VIEW,
    //   onRenderViewCreatedListener: (viewId) {
    //     _controller?.setPlayerView(viewId);
    //   },
    // );
    return const SizedBox.shrink(); // placeholder until super_player is available
  }

  // ── 播放控制 ──────────────────────────────────────────────────

  @override
  Future<void> setLoop(bool loop) async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // _controller.setLoop(loop);
  }

  @override
  Future<void> setVolume(double volume) async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // _controller.setAudioPlayoutVolume((volume * 100).toInt());
  }

  @override
  Future<void> setMute(bool mute) async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // _controller.setMute(mute);
  }

  @override
  Future<void> setRate(double rate) async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // _controller.setRate(rate);
  }

  @override
  Future<void> preload() async {
    if (_controller == null) return;
    // TODO: requires super_player SDK
    // 腾讯播放器通过 startVodPlay 触发预加载，此处为空实现
  }

  // ── 监听器 ────────────────────────────────────────────────────

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    // TODO: requires super_player SDK
    // _controller?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    // TODO: requires super_player SDK
    // _controller?.removeListener(listener);
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

  // ── 内部事件处理 ──────────────────────────────────────────────

  /// 处理腾讯播放器 SDK 事件。
  ///
  /// 事件类型对应 `TXVodPlayEvent` 中的常量：
  /// - `PLAY_EVT_PLAY_PROGRESS`：播放进度更新
  /// - `PLAY_EVT_VOD_PLAY_PREPARED`：视频就绪（可获取宽高）
  /// - `PLAY_EVT_CHANGE_RESOLUTION`：分辨率变化
  /// - `PLAY_EVT_PLAY_LOADING`：开始缓冲
  /// - `PLAY_EVT_VOD_LOADING_END`：缓冲结束
  /// - `PLAY_EVT_PLAY_BEGIN`：开始播放
  /// - `PLAY_EVT_PLAY_END`：播放完成
  /// - `PLAY_ERR_NET_DISCONNECT`：网络断开
  void _onPlayerEvent(dynamic event) {
    // TODO: requires super_player SDK
    // final evtId = event[TXVodPlayEvent.EVT_ID] as int?;
    // if (evtId == null) return;
    //
    // switch (evtId) {
    //   case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
    //     final posMs = (event[TXVodPlayEvent.EVT_PLAY_PROGRESS_MS] as int?) ?? 0;
    //     final durMs = (event[TXVodPlayEvent.EVT_PLAY_DURATION_MS] as int?) ?? 0;
    //     final bufPercent = (event[TXVodPlayEvent.EVT_PLAYABLE_DURATION_MS] as int?) ?? 0;
    //     videoData.posMilli = posMs;
    //     videoData.duration = Duration(milliseconds: durMs);
    //     videoData.bufferPercent = durMs > 0 ? (bufPercent * 100 ~/ durMs) : 0;
    //     _onPositionUpdateCallback?.call(Duration(milliseconds: posMs));
    //     _onBufferUpdateCallback?.call(videoData.bufferPercent);
    //
    //   case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED:
    //   case TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION:
    //     final w = (event[TXVodPlayEvent.EVT_VIDEO_WIDTH] as int?)?.toDouble() ?? 0;
    //     final h = (event[TXVodPlayEvent.EVT_VIDEO_HEIGHT] as int?)?.toDouble() ?? 0;
    //     videoData.width = w;
    //     videoData.height = h;
    //     if (w > 0 && h > 0) videoData.aspectRatio = w / h;
    //     videoData.videoRenderStart = true;
    //     _onPreparedCallback?.call(true);
    //
    //   case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
    //     updateState(YuNiPlayerState.buffering);
    //
    //   case TXVodPlayEvent.PLAY_EVT_VOD_LOADING_END:
    //   case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
    //     if (state == YuNiPlayerState.buffering) {
    //       updateState(YuNiPlayerState.playing);
    //     }
    //
    //   case TXVodPlayEvent.PLAY_EVT_PLAY_END:
    //     updateState(YuNiPlayerState.completed);
    //
    //   case TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT:
    //     videoData.lastError = 'Network disconnected (event: $evtId)';
    //     updateState(YuNiPlayerState.error);
    // }
  }

  // ── 内部工具 ──────────────────────────────────────────────────

  /// 解析视频播放 URL（优先使用 url，其次使用 file 路径）
  String _resolveUrl() {
    if (videoSource.url != null) return videoSource.url!;
    if (videoSource.file != null) return videoSource.file!.path;
    throw StateError('TXPlayerEngine: videoSource has no url or file');
  }
}
