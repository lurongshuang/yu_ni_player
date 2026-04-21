import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:super_player/super_player.dart';

import 'package:yu_ni_player_base/yu_ni_player_base.dart';

/// 腾讯超级播放器引擎，适用于 iOS 和 Android 平台。
///
/// 依赖 `super_player` SDK（`TXVodPlayerController`、`TXPlayerVideo` 等）。
/// 使用前需调用 [initLicense] 完成 SDK 授权初始化。
class TXPlayerEngine extends YuNiPlayerEngine {
  TXPlayerEngine(super.source);

  TXVodPlayerController? _controller;

  // ── 回调 ──────────────────────────────────────────────────────
  void Function(Duration)? _onPositionUpdateCallback;
  void Function(int)? _onBufferUpdateCallback;
  void Function(bool)? _onPreparedCallback;

  // ── 监听器列表 ────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── 静态初始化 ────────────────────────────────────────────────

  /// 初始化腾讯播放器 SDK 许可证。
  ///
  /// 必须在 `main()` 中、`runApp()` 之前调用一次。
  /// 仅在 iOS 和 Android 平台上生效。
  static void initLicense(String licenseUrl, String licenseKey) {
    if (!Platform.isIOS && !Platform.isAndroid) return;
    SuperPlayerPlugin.setGlobalLicense(licenseUrl, licenseKey);
    SuperPlayerPlugin.setGlobalMaxCacheSize(200);
    SuperPlayerPlugin.setGlobalCacheFolderPath('videos');
  }

  // ── isPrepared ────────────────────────────────────────────────

  @override
  bool get isPrepared {
    if (_controller == null) return false;
    return state != YuNiPlayerState.idle && state != YuNiPlayerState.error;
  }

  // ── performInit ───────────────────────────────────────────────

  @override
  Future<void> performInit() async {
    _controller = TXVodPlayerController();
    _controller!.onPlayerEventBroadcast.listen(_onPlayerEvent);
    instanceCode.value = _controller.hashCode;

    final txConfig = FTXVodPlayConfig();
    final mergedHeaders = videoSource.mergedHeaders(config.headers);
    if (mergedHeaders.isNotEmpty) {
      txConfig.headers = mergedHeaders;
    }
    await _controller!.setConfig(txConfig);
    await _controller!.setAutoPlay(isAutoPlay: false);
    await _controller!.enableHardwareDecode(config.hardwareAcceleration);
    await _controller!.setRenderMode(FTXPlayerRenderMode.ADJUST_RESOLUTION);
    await _controller!.startVodPlay(_resolveUrl());
  }

  // ── performPlay ───────────────────────────────────────────────

  @override
  Future<void> performPlay() async {
    await _controller?.resume();
  }

  // ── performPause ──────────────────────────────────────────────

  @override
  Future<void> performPause() async {
    await _controller?.pause();
  }

  // ── performSeek ───────────────────────────────────────────────

  @override
  Future<void> performSeek(double seconds) async {
    _controller?.seek(seconds);
  }

  // ── performDispose ────────────────────────────────────────────

  @override
  Future<void> performDispose() async {
    await _controller?.dispose();
    _controller = null;
    _listeners.clear();
  }

  // ── performRelease ────────────────────────────────────────────

  @override
  Future<void> performRelease() async {
    await _controller?.dispose();
    _controller = null;
    _onPreparedCallback?.call(false);
    if (!isDisposed) {
      instanceCode.value = instanceCode.value + 1;
    }
  }

  // ── buildView ─────────────────────────────────────────────────

  @override
  Widget buildView() {
    if (_controller == null) return const SizedBox.shrink();
    return TXPlayerVideo(
      androidRenderType: FTXAndroidRenderViewType.TEXTURE_VIEW,
      onRenderViewCreatedListener: (viewId) {
        _controller?.setPlayerView(viewId);
      },
    );
  }

  // ── 播放控制实现 ──────────────────────────────────────────────

  @override
  Future<void> performSetLoop(bool loop) async {
    await _controller?.setLoop(loop);
  }

  @override
  Future<void> performSetVolume(double volume) async {
    await _controller?.setAudioPlayoutVolume((volume * 100).toInt());
  }

  @override
  Future<void> performSetMute(bool mute) async {
    await _controller?.setMute(mute);
  }

  @override
  Future<void> performSetRate(double rate) async {
    await _controller?.setRate(rate);
  }

  @override
  Future<void> preload() async {
    // 腾讯播放器通过 startVodPlay 触发预加载
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

  // ── 内部事件处理 ──────────────────────────────────────────────

  void _onPlayerEvent(dynamic event) {
    final evtId = event["event"] as int?;
    if (evtId == null) return;

    switch (evtId) {
      case TXVodPlayEvent.PLAY_EVT_PLAY_PROGRESS:
        final posMs =
            (event[TXVodPlayEvent.EVT_PLAY_PROGRESS_MS] as int?) ?? 0;
        final durMs =
            (event[TXVodPlayEvent.EVT_PLAY_DURATION_MS] as int?) ?? 0;
        final bufMs =
            (event[TXVodPlayEvent.EVT_PLAYABLE_DURATION_MS] as int?) ?? 0;
        videoData.posMilli = posMs;
        videoData.duration = Duration(milliseconds: durMs);
        if (durMs > 0) {
          videoData.bufferPercent = (bufMs * 100 ~/ durMs).clamp(0, 100);
          _onBufferUpdateCallback?.call(videoData.bufferPercent);
        }
        _onPositionUpdateCallback?.call(Duration(milliseconds: posMs));
        _notifyListeners();

      case TXVodPlayEvent.PLAY_EVT_VOD_PLAY_PREPARED:
      case TXVodPlayEvent.PLAY_EVT_CHANGE_RESOLUTION:
        final w =
            (event[TXVodPlayEvent.EVT_VIDEO_WIDTH] as int?)?.toDouble() ?? 0;
        final h =
            (event[TXVodPlayEvent.EVT_VIDEO_HEIGHT] as int?)?.toDouble() ?? 0;
        if (w > 0 && h > 0) {
          videoData.width = w;
          videoData.height = h;
          videoData.aspectRatio = w / h;
          videoData.videoRenderStart = true;
          _onPreparedCallback?.call(true);
        }

      case TXVodPlayEvent.PLAY_EVT_PLAY_LOADING:
        updateState(YuNiPlayerState.buffering);

      case TXVodPlayEvent.PLAY_EVT_VOD_LOADING_END:
      case TXVodPlayEvent.PLAY_EVT_PLAY_BEGIN:
        if (state == YuNiPlayerState.buffering ||
            state == YuNiPlayerState.loading) {
          updateState(YuNiPlayerState.playing);
        }

      case TXVodPlayEvent.PLAY_EVT_PLAY_END:
        updateState(YuNiPlayerState.completed);

      case TXVodPlayEvent.PLAY_ERR_NET_DISCONNECT:
      case TXVodPlayEvent.PLAY_ERR_FILE_NOT_FOUND:
        videoData.lastError = 'Playback error (event: $evtId)';
        updateState(YuNiPlayerState.error);
    }
  }

  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }

  // ── 内部工具 ──────────────────────────────────────────────────

  String _resolveUrl() {
    if (videoSource.url != null) return videoSource.url!;
    if (videoSource.file != null) return videoSource.file!.path;
    throw StateError('TXPlayerEngine: videoSource has no url or file');
  }
}
