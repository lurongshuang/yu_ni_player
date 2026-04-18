import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';
import 'package:yu_ni_player/yu_ni_player.dart';

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

  VideoPlayerController _buildController() {
    if (videoSource.file != null) {
      return VideoPlayerController.file(videoSource.file!);
    }
    return VideoPlayerController.networkUrl(
      Uri.parse(videoSource.url!),
      httpHeaders: config.headers,
    );
  }

  @override
  bool get isPrepared {
    final c = _controller;
    if (c == null) return false;
    return c.value.isInitialized && !c.value.hasError;
  }

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

  @override
  Future<void> performPlay() async => _controller?.play();

  @override
  Future<void> performPause() async => _controller?.pause();

  @override
  Future<void> performSeek(double seconds) async =>
      _controller?.seekTo(Duration(milliseconds: (seconds * 1000).toInt()));

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

  @override
  Future<void> performRelease() async {
    final c = _controller;
    if (c != null) {
      c.removeListener(_onControllerUpdate);
      _controller = null;
      await c.dispose();
    }
    _onPreparedCallback?.call(false);
    instanceCode.value = instanceCode.value + 1;
  }

  @override
  Widget buildView() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return VideoPlayer(c);
  }

  @override
  Future<void> setLoop(bool loop) async => _controller?.setLooping(loop);

  @override
  Future<void> setVolume(double volume) async => _controller?.setVolume(volume);

  @override
  Future<void> setMute(bool mute) async =>
      _controller?.setVolume(mute ? 0.0 : 1.0);

  @override
  Future<void> setRate(double rate) async =>
      _controller?.setPlaybackSpeed(rate);

  @override
  Future<void> preload() async {}

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

  @override
  void onPositionUpdate(void Function(Duration) callback) =>
      _onPositionUpdateCallback = callback;

  @override
  void onBufferUpdate(void Function(int percent) callback) =>
      _onBufferUpdateCallback = callback;

  @override
  void onPrepared(void Function(bool prepared) callback) =>
      _onPreparedCallback = callback;

  void _onControllerUpdate() {
    final c = _controller;
    if (c == null || isDisposed) return;
    final value = c.value;

    videoData.duration = value.duration;
    videoData.posMilli = value.position.inMilliseconds;

    if (value.isInitialized && value.size.width > 0 && value.size.height > 0) {
      videoData.width = value.size.width;
      videoData.height = value.size.height;
      videoData.aspectRatio = value.aspectRatio;
      videoData.videoRenderStart = true;
      _onPreparedCallback?.call(true);
    }

    if (value.duration.inMilliseconds > 0 && value.buffered.isNotEmpty) {
      final bufferedEnd = value.buffered.last.end.inMilliseconds;
      videoData.bufferPercent =
          (bufferedEnd * 100 ~/ value.duration.inMilliseconds).clamp(0, 100);
      _onBufferUpdateCallback?.call(videoData.bufferPercent);
    }

    _onPositionUpdateCallback?.call(value.position);

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
