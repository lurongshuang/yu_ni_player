import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../core/yu_ni_player_engine.dart';
import '../core/yu_ni_player_state.dart';

/// media_kit 引擎，适用于全平台（Android / iOS / macOS / Windows / Linux / Web）。
///
/// 依赖 `media_kit`、`media_kit_video`、`media_kit_libs_video` 包。
/// 使用前需在 `main()` 中调用 [initLicense] 完成 SDK 初始化。
///
/// ```dart
/// void main() {
///   WidgetsFlutterBinding.ensureInitialized();
///   MediaKitEngine.initLicense(); // 必须在 runApp 之前调用
///   YuNiPlayerPlugin.initialize(...);
///   runApp(const MyApp());
/// }
/// ```
class MediaKitEngine extends YuNiPlayerEngine {
  MediaKitEngine(super.source);

  Player? _player;
  VideoController? _videoController;

  // ── 订阅 ──────────────────────────────────────────────────────
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _bufferSub;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<bool>? _completedSub;
  StreamSubscription<bool>? _bufferingSub;
  StreamSubscription<Duration>? _durationSub;
  StreamSubscription<VideoParams>? _videoParamsSub;
  StreamSubscription<String>? _errorSub;

  // ── 回调 ──────────────────────────────────────────────────────
  void Function(Duration)? _onPositionUpdateCallback;
  void Function(int)? _onBufferUpdateCallback;
  void Function(bool)? _onPreparedCallback;

  // ── 监听器列表 ────────────────────────────────────────────────
  final List<VoidCallback> _listeners = [];

  // ── 静态初始化 ────────────────────────────────────────────────

  /// 初始化 media_kit SDK。
  ///
  /// 必须在 `main()` 中、`runApp()` 之前调用一次。
  ///
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   MediaKitEngine.initLicense();
  ///   runApp(const MyApp());
  /// }
  /// ```
  static void initLicense() {
    MediaKit.ensureInitialized();
  }

  // ── isPrepared ────────────────────────────────────────────────

  @override
  bool get isPrepared {
    final p = _player;
    if (p == null) return false;
    return state != YuNiPlayerState.idle && state != YuNiPlayerState.error;
  }

  // ── performInit ───────────────────────────────────────────────

  @override
  Future<void> performInit() async {
    _player = Player();
    _videoController = VideoController(_player!);
    instanceCode.value = _player.hashCode;

    _subscribeToEvents();

    final media = videoSource.file != null
        ? Media(videoSource.file!.path, httpHeaders: config.headers)
        : Media(videoSource.url!, httpHeaders: config.headers);

    await _player!.open(media, play: false);
  }

  // ── performPlay ───────────────────────────────────────────────

  @override
  Future<void> performPlay() async {
    await _player?.play();
  }

  // ── performPause ──────────────────────────────────────────────

  @override
  Future<void> performPause() async {
    await _player?.pause();
  }

  // ── performSeek ───────────────────────────────────────────────

  @override
  Future<void> performSeek(double seconds) async {
    await _player?.seek(Duration(milliseconds: (seconds * 1000).toInt()));
  }

  // ── performDispose ────────────────────────────────────────────

  @override
  Future<void> performDispose() async {
    await _cancelSubscriptions();
    await _player?.dispose();
    _player = null;
    _videoController = null;
    _listeners.clear();
  }

  // ── performRelease ────────────────────────────────────────────

  @override
  Future<void> performRelease() async {
    await _cancelSubscriptions();
    await _player?.dispose();
    _player = null;
    _videoController = null;
    _onPreparedCallback?.call(false);
    instanceCode.value = instanceCode.value + 1;
  }

  // ── buildView ─────────────────────────────────────────────────

  @override
  Widget buildView() {
    final vc = _videoController;
    if (vc == null) return const SizedBox.shrink();
    return Video(controller: vc, controls: NoVideoControls);
  }

  // ── 播放控制 ──────────────────────────────────────────────────

  @override
  Future<void> setLoop(bool loop) async {
    await _player?.setPlaylistMode(
      loop ? PlaylistMode.single : PlaylistMode.none,
    );
  }

  @override
  Future<void> setVolume(double volume) async {
    await _player?.setVolume(volume * 100);
  }

  @override
  Future<void> setMute(bool mute) async {
    await _player?.setVolume(mute ? 0.0 : 100.0);
  }

  @override
  Future<void> setRate(double rate) async {
    await _player?.setRate(rate);
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

  // ── 内部事件订阅 ──────────────────────────────────────────────

  void _subscribeToEvents() {
    final p = _player;
    if (p == null) return;

    // 播放位置
    _positionSub = p.stream.position.listen((pos) {
      videoData.posMilli = pos.inMilliseconds;
      _onPositionUpdateCallback?.call(pos);
      _notifyListeners();
    });

    // 缓冲位置
    _bufferSub = p.stream.buffer.listen((buf) {
      final dur = p.state.duration;
      if (dur.inMilliseconds > 0) {
        videoData.bufferPercent =
            (buf.inMilliseconds * 100 ~/ dur.inMilliseconds).clamp(0, 100);
        _onBufferUpdateCallback?.call(videoData.bufferPercent);
      }
    });

    // 时长
    _durationSub = p.stream.duration.listen((dur) {
      videoData.duration = dur;
    });

    // 视频参数（宽高比）
    _videoParamsSub = p.stream.videoParams.listen((params) {
      final w = params.dw?.toDouble() ?? 0;
      final h = params.dh?.toDouble() ?? 0;
      if (w > 0 && h > 0) {
        videoData.width = w;
        videoData.height = h;
        videoData.aspectRatio = w / h;
        videoData.videoRenderStart = true;
        _onPreparedCallback?.call(true);
      }
    });

    // 播放/暂停状态
    _playingSub = p.stream.playing.listen((playing) {
      if (playing) {
        updateState(YuNiPlayerState.playing);
      } else if (state == YuNiPlayerState.playing) {
        updateState(YuNiPlayerState.paused);
      }
    });

    // 缓冲状态
    _bufferingSub = p.stream.buffering.listen((buffering) {
      if (buffering) {
        updateState(YuNiPlayerState.buffering);
      } else if (state == YuNiPlayerState.buffering) {
        // 缓冲结束，恢复到播放或暂停
        updateState(
          p.state.playing ? YuNiPlayerState.playing : YuNiPlayerState.paused,
        );
      }
    });

    // 播放完成
    _completedSub = p.stream.completed.listen((completed) {
      if (completed) {
        updateState(YuNiPlayerState.completed);
      }
    });

    // 错误
    _errorSub = p.stream.error.listen((error) {
      if (error.isNotEmpty) {
        videoData.lastError = error;
        updateState(YuNiPlayerState.error);
      }
    });
  }

  Future<void> _cancelSubscriptions() async {
    await _positionSub?.cancel();
    await _bufferSub?.cancel();
    await _durationSub?.cancel();
    await _videoParamsSub?.cancel();
    await _playingSub?.cancel();
    await _bufferingSub?.cancel();
    await _completedSub?.cancel();
    await _errorSub?.cancel();
    _positionSub = null;
    _bufferSub = null;
    _durationSub = null;
    _videoParamsSub = null;
    _playingSub = null;
    _bufferingSub = null;
    _completedSub = null;
    _errorSub = null;
  }

  void _notifyListeners() {
    for (final l in _listeners) {
      l();
    }
  }
}
