import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import 'package:yu_ni_player_base/yu_ni_player_base.dart';

/// video_player 引擎，适用于 macOS、Windows、Web 及 iOS/Android 平台。
///
/// 使用 Flutter 官方 `video_player` 包实现，无需额外许可证。
class VideoPlayerKitEngine extends YuNiPlayerEngine {
  VideoPlayerKitEngine(super.source);

  VideoPlayerController? _controller;

  void Function(Duration)? _onPositionUpdateCallback;
  void Function(int)? _onBufferUpdateCallback;
  void Function(bool)? _onPreparedCallback;

  final List<VoidCallback> _listeners = [];

  /// video_player 不需要许可证初始化。
  static void initLicense() {}

  // ── 内部工具 ──────────────────────────────────────────────────

  VideoPlayerController _buildController() {
    if (videoSource.file != null) {
      return VideoPlayerController.file(videoSource.file!);
    }
    return VideoPlayerController.networkUrl(
      Uri.parse(videoSource.url!),
      httpHeaders: videoSource.mergedHeaders(config.headers),
    );
  }

  // ── isPrepared ────────────────────────────────────────────────

  @override
  bool get isPrepared {
    final c = _controller;
    if (c == null) return false;
    return c.value.isInitialized && !c.value.hasError;
  }

  // ── performInit ───────────────────────────────────────────────

  @override
  Future<void> performInit() async {
    _controller = _buildController();
    _controller!.addListener(_onControllerUpdate);
    instanceCode.value = _controller.hashCode;

    int retries = 0;
    while (true) {
      try {
        await _controller!.initialize();
        return;
      } catch (e) {
        retries++;
        if (retries > 2) {
          videoData.lastError = e;
          rethrow;
        }
        _controller!.removeListener(_onControllerUpdate);
        await _controller!.dispose();
        _controller = _buildController();
        _controller!.addListener(_onControllerUpdate);
        instanceCode.value = _controller.hashCode;
        await Future.delayed(Duration(milliseconds: 500 * retries));
      }
    }
  }

  // ── performPlay ───────────────────────────────────────────────

  @override
  Future<void> performPlay() async {
    await _controller?.play();
  }

  // ── performPause ──────────────────────────────────────────────

  @override
  Future<void> performPause() async {
    await _controller?.pause();
  }

  // ── performSeek ───────────────────────────────────────────────

  @override
  Future<void> performSeek(double seconds) async {
    await _controller?.seekTo(Duration(milliseconds: (seconds * 1000).toInt()));
  }

  // ── performDispose ────────────────────────────────────────────

  @override
  Future<void> performDispose() async {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onControllerUpdate);
      await c.dispose();
      _controller = null;
    }
    _listeners.clear();
  }

  // ── performRelease ────────────────────────────────────────────

  @override
  Future<void> performRelease() async {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onControllerUpdate);
      _controller = null;
      await c.dispose();
    }
    _onPreparedCallback?.call(false);
    if (!isDisposed) {
      instanceCode.value = instanceCode.value + 1;
    }
  }

  // ── buildView ─────────────────────────────────────────────────

  @override
  Widget buildView() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return VideoPlayer(c);
  }

  // ── 播放控制实现 ──────────────────────────────────────────────

  @override
  Future<void> performSetLoop(bool loop) async {
    await _controller?.setLooping(loop);
  }

  @override
  Future<void> performSetVolume(double volume) async {
    await _controller?.setVolume(volume);
  }

  @override
  Future<void> performSetMute(bool mute) async {
    await _controller?.setVolume(mute ? 0.0 : 1.0);
  }

  @override
  Future<void> performSetRate(double rate) async {
    await _controller?.setPlaybackSpeed(rate);
  }

  @override
  Future<void> preload() async {
    // video_player 通过 initialize() 触发预加载
  }

  // ── 监听器 ────────────────────────────────────────────────────

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    _controller?.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    _controller?.removeListener(listener);
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

  // ── 内部控制器状态监听 ────────────────────────────────────────

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || isDisposed) return;

    final value = c.value;

    // 更新 videoData
    videoData.duration = value.duration;
    videoData.posMilli = value.position.inMilliseconds;

    // 更新宽高比
    if (value.isInitialized && value.size.width > 0 && value.size.height > 0) {
      videoData.width = value.size.width;
      videoData.height = value.size.height;
      videoData.aspectRatio = value.aspectRatio;
      videoData.videoRenderStart = true;
      _onPreparedCallback?.call(true);
    }

    // 更新缓冲进度
    if (value.duration.inMilliseconds > 0 && value.buffered.isNotEmpty) {
      final bufferedEnd = value.buffered.last.end.inMilliseconds;
      videoData.bufferPercent =
          (bufferedEnd * 100 ~/ value.duration.inMilliseconds).clamp(0, 100);
      _onBufferUpdateCallback?.call(videoData.bufferPercent);
    }

    // 更新播放进度回调
    _onPositionUpdateCallback?.call(value.position);

    // 更新状态
    if (value.hasError) {
      videoData.lastError = value.errorDescription;
      updateState(YuNiPlayerState.error);
    } else if (value.isBuffering) {
      updateState(YuNiPlayerState.buffering);
    } else if (value.isPlaying) {
      updateState(YuNiPlayerState.playing);
    } else if (value.isInitialized &&
        value.position >= value.duration &&
        value.duration > Duration.zero) {
      updateState(YuNiPlayerState.completed);
    }
  }
}
