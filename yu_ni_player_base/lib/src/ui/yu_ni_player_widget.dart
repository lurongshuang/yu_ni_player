import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/yu_ni_player_engine.dart';
import 'yu_ni_player_controls.dart'
    show YuNiDefaultControls, YuNiControlsBuilder, YuNiControlsContext;

/// 视频播放器 Widget
///
/// 全屏逻辑：
/// - 点击全屏按钮，通过 [Navigator.push] 推一个透明全屏路由，不改变系统方向
/// - 系统返回键天然 pop 全屏路由，[PopScope] 拦截后执行退出逻辑
/// - 全屏内提供旋转按钮，用 [Transform.rotate] 旋转视频画面
/// - 旋转比例计算：横屏时 AspectRatio 用旋转前坐标系的比例（screenH/screenW）
class YuNiPlayer extends StatefulWidget {
  const YuNiPlayer({
    super.key,
    required this.player,
    this.backgroundColor,
    this.loadingBuilder,
    this.errorBuilder,
    this.showDefaultControls = false,
    this.controlsBuilder,
    this.aspectRatio,
    this.onFullscreenChanged,
    this.allowFullscreen = true,
    this.extraControls,
    this.fullscreenPadding,
    this.fullscreenControlsBuilder,
  });

  final YuNiPlayerEngine player;
  final Color? backgroundColor;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final bool showDefaultControls;
  final YuNiControlsBuilder? controlsBuilder;
  final double? aspectRatio;
  final void Function(bool isFullscreen)? onFullscreenChanged;
  final bool allowFullscreen;

  /// 额外添加到底部控制栏右侧的组件列表（仅在 showDefaultControls 为 true 时生效）
  final List<Widget>? extraControls;

  /// 全屏模式下的控制栏边距
  final EdgeInsetsGeometry? fullscreenPadding;

  /// 全屏模式下的专属控制栏构建器
  final YuNiControlsBuilder? fullscreenControlsBuilder;

  @override
  State<YuNiPlayer> createState() => _YuNiPlayerState();
}

class _YuNiPlayerState extends State<YuNiPlayer> with WidgetsBindingObserver {
  bool _wasPlayingBeforePause = false;
  bool _isFullscreen = false;
  bool _isMuted = false;
  double _rate = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.player.instanceCode.addListener(_onInstanceChanged);
    widget.player.stateNotifier.addListener(_onStateChanged);
    _isMuted = widget.player.config.mute;
    _rate = widget.player.config.speed;
  }

  @override
  void didUpdateWidget(covariant YuNiPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.player != oldWidget.player) {
      oldWidget.player.instanceCode.removeListener(_onInstanceChanged);
      oldWidget.player.stateNotifier.removeListener(_onStateChanged);
      widget.player.instanceCode.addListener(_onInstanceChanged);
      widget.player.stateNotifier.addListener(_onStateChanged);
      _wasPlayingBeforePause = false;
      _isMuted = widget.player.config.mute;
      _rate = widget.player.config.speed;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.player.instanceCode.removeListener(_onInstanceChanged);
    widget.player.stateNotifier.removeListener(_onStateChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        if (widget.player.isPlaying) {
          _wasPlayingBeforePause = true;
          widget.player.pause();
        } else {
          _wasPlayingBeforePause = false;
        }
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          widget.player.play();
          _wasPlayingBeforePause = false;
        }
      default:
        break;
    }
  }

  void _onInstanceChanged() {
    if (mounted) setState(() {});
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  // ── 全屏：push 透明路由，系统返回键天然 pop ──────────────────

  Future<void> enterFullscreen() async {
    if (_isFullscreen || !widget.allowFullscreen) return;
    if (!mounted) return;

    setState(() => _isFullscreen = true);
    widget.onFullscreenChanged?.call(true);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    await Navigator.of(context, rootNavigator: true).push(
      _FullscreenRoute(
        builder: (ctx) => _FullscreenPage(
          player: widget.player,
          controlsBuilder: widget.controlsBuilder,
          showDefaultControls: widget.showDefaultControls,
          extraControls: widget.extraControls,
          fullscreenPadding: widget.fullscreenPadding,
          fullscreenControlsBuilder: widget.fullscreenControlsBuilder,
          buildControlsContext: _buildControlsContext,
          onExit: () => Navigator.of(ctx, rootNavigator: true).pop(),
        ),
      ),
    );

    // push 返回 = 全屏路由已 pop（无论按钮还是系统返回键）
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) {
      setState(() => _isFullscreen = false);
      widget.onFullscreenChanged?.call(false);
    }
  }

  void exitFullscreen() {
    if (!_isFullscreen) return;
    Navigator.of(context, rootNavigator: true).maybePop();
  }

  void toggleFullscreen() {
    _isFullscreen ? exitFullscreen() : enterFullscreen();
  }

  void _onPlay() => widget.player.play();

  void _onPause() => widget.player.pause();

  void _onSeek(double seconds) => widget.player.seek(seconds);

  void _onSetRate(double rate) {
    setState(() => _rate = rate);
    widget.player.setRate(rate);
  }

  void _onSetMute(bool mute) {
    setState(() => _isMuted = mute);
    widget.player.setMute(mute);
  }

  YuNiControlsContext _buildControlsContext() {
    return YuNiControlsContext(
      player: widget.player,
      isFullscreen: _isFullscreen,
      isMuted: _isMuted,
      rate: _rate,
      onPlay: _onPlay,
      onPause: _onPause,
      onSeek: _onSeek,
      onToggleFullscreen: toggleFullscreen,
      onSetRate: _onSetRate,
      onSetMute: _onSetMute,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = widget.player.state;
    final ar = widget.aspectRatio ??
        widget.player.videoData.aspectRatio ??
        (16.0 / 9.0);

    return Material(
      color: widget.backgroundColor ?? Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: ar,
          child: Stack(
            fit: StackFit.expand,
            children: [
              widget.player.buildView(),
              if (widget.loadingBuilder != null &&
                  (playerState == YuNiPlayerState.loading ||
                      playerState == YuNiPlayerState.buffering))
                widget.loadingBuilder!(context),
              if (widget.errorBuilder != null &&
                  playerState == YuNiPlayerState.error)
                widget.errorBuilder!(
                    context, widget.player.videoData.lastError),
              if (widget.controlsBuilder != null)
                Positioned.fill(
                  child:
                      widget.controlsBuilder!(context, _buildControlsContext()),
                )
              else if (widget.showDefaultControls)
                Positioned.fill(
                  child: YuNiDefaultControls(
                    controls: _buildControlsContext(),
                    padding: widget.fullscreenPadding,
                    extraActions: widget.extraControls,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 全屏路由（无动画透明路由）────────────────────────────────────────────────

class _FullscreenRoute extends PageRoute<void> {
  _FullscreenRoute({required this.builder}) : super(fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  Color? get barrierColor => Colors.black;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation) {
    return builder(context);
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return child;
  }
}

// ── 全屏页面 ──────────────────────────────────────────────────────────────────

class _FullscreenPage extends StatefulWidget {
  const _FullscreenPage({
    required this.player,
    this.controlsBuilder,
    this.showDefaultControls = false,
    this.extraControls,
    this.fullscreenPadding,
    this.fullscreenControlsBuilder,
    required this.buildControlsContext,
    required this.onExit,
  });

  final YuNiPlayerEngine player;
  final YuNiControlsBuilder? controlsBuilder;
  final bool showDefaultControls;
  final List<Widget>? extraControls;
  final EdgeInsetsGeometry? fullscreenPadding;
  final YuNiControlsBuilder? fullscreenControlsBuilder;
  final YuNiControlsContext Function() buildControlsContext;
  final VoidCallback onExit;

  @override
  State<_FullscreenPage> createState() => _FullscreenPageState();
}

class _FullscreenPageState extends State<_FullscreenPage> {
  /// 是否手动横屏
  bool _isManualLandscape = false;

  @override
  void initState() {
    super.initState();
    widget.player.instanceCode.addListener(_rebuild);
    widget.player.stateNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.player.instanceCode.removeListener(_rebuild);
    widget.player.stateNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _toggleManualRotation() {
    setState(() {
      _isManualLandscape = !_isManualLandscape;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onExit();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenW = media.size.width;
    final screenH = media.size.height;
    final videoAr = widget.player.videoData.aspectRatio ?? (16.0 / 9.0);

    Widget videoContent;
    if (_isManualLandscape) {
      videoContent = RotatedBox(
        quarterTurns: 1,
        child: SizedBox(
          width: screenH,
          height: screenW,
          child: Stack(
            fit: StackFit.expand,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: videoAr * 1000,
                  height: 1000,
                  child: widget.player.buildView(),
                ),
              ),
              _buildControls(isLandscape: true),
            ],
          ),
        ),
      );
    } else {
      videoContent = Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: videoAr * 1000,
              height: 1000,
              child: widget.player.buildView(),
            ),
          ),
          _buildControls(isLandscape: false),
        ],
      );
    }

    return Stack(
      children: [
        videoContent,
      ],
    );
  }

  Widget _buildControls({required bool isLandscape}) {
    final fsBuilder =
        widget.fullscreenControlsBuilder ?? widget.controlsBuilder;
    if (fsBuilder != null) {
      return fsBuilder(context, widget.buildControlsContext());
    }
    if (widget.showDefaultControls) {
      return YuNiFullscreenControls(
        controls: widget.buildControlsContext(),
        isLandscape: isLandscape,
        extraControls: widget.extraControls,
        padding: widget.fullscreenPadding,
        onToggleRotation: _toggleManualRotation,
        onExit: widget.onExit,
      );
    }
    return const SizedBox.shrink();
  }
}

/// 全屏控制栏
class YuNiFullscreenControls extends StatefulWidget {
  const YuNiFullscreenControls({
    super.key,
    required this.controls,
    required this.isLandscape,
    this.extraControls,
    this.padding,
    required this.onToggleRotation,
    required this.onExit,
  });

  final YuNiControlsContext controls;
  final bool isLandscape;
  final List<Widget>? extraControls;
  final EdgeInsetsGeometry? padding;
  final VoidCallback onToggleRotation;
  final VoidCallback onExit;

  @override
  State<YuNiFullscreenControls> createState() => _YuNiFullscreenControlsState();
}

class _YuNiFullscreenControlsState extends State<YuNiFullscreenControls>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  bool _dragging = false;
  double _dragValue = 0;
  Timer? _hideTimer;
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    widget.controls.player.addListener(_onPlayerUpdate);
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeCtrl.dispose();
    widget.controls.player.removeListener(_onPlayerUpdate);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant YuNiFullscreenControls old) {
    super.didUpdateWidget(old);
    if (!widget.controls.isPlaying && !_visible) _show();
    if (widget.controls.isPlaying &&
        old.controls.state != widget.controls.state) {
      _scheduleHide();
    }
    if (widget.controls.player != old.controls.player) {
      old.controls.player.removeListener(_onPlayerUpdate);
      widget.controls.player.addListener(_onPlayerUpdate);
    }
  }

  void _onPlayerUpdate() {
    if (mounted) setState(() {});
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!widget.controls.isPlaying) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_dragging && _visible) {
        _fadeCtrl.reverse();
        setState(() => _visible = false);
      }
    });
  }

  void _show() {
    _hideTimer?.cancel();
    _fadeCtrl.forward();
    setState(() => _visible = true);
    _scheduleHide();
  }

  void _toggle() {
    if (_visible) {
      _hideTimer?.cancel();
      _fadeCtrl.reverse();
      setState(() => _visible = false);
    } else {
      _show();
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controls;
    const primary = Colors.white;
    const bg = Color(0xBB000000);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: Stack(
        children: [
          if (c.isLoading)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          if (c.isError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 8),
                  const Text('播放失败',
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: c.onPlay,
                    child:
                        const Text('重试', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          if (c.isCompleted)
            Center(
              child: GestureDetector(
                onTap: () => c.onSeek(0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child:
                      const Icon(Icons.replay, color: Colors.white, size: 36),
                ),
              ),
            ),
          FadeTransition(
            opacity: _fadeCtrl,
            child: _visible
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, bg],
                          ),
                        ),
                        padding: widget.padding ??
                            const EdgeInsets.fromLTRB(8, 24, 8, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProgressBar(
                              progress: c.progress,
                              bufferPercent: c.bufferPercent,
                              primaryColor: primary,
                              onDragStart: () {
                                _dragging = true;
                                _dragValue = c.progress;
                                _hideTimer?.cancel();
                              },
                              onDragUpdate: (v) =>
                                  setState(() => _dragValue = v),
                              onDragEnd: (v) {
                                _dragging = false;
                                c.onSeek(v * c.duration.inSeconds.toDouble());
                                _scheduleHide();
                              },
                              dragValue: _dragging ? _dragValue : null,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: c.isPlaying ? c.onPause : c.onPlay,
                                  icon: Icon(
                                    c.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: primary,
                                  ),
                                ),
                                Text(
                                  '${_fmt(c.position)} / ${_fmt(c.duration)}',
                                  style: const TextStyle(
                                      color: primary, fontSize: 12),
                                ),
                                const Spacer(),
                                if (widget.extraControls != null)
                                  ...widget.extraControls!,
                                _RateButton(
                                    rate: c.rate,
                                    color: primary,
                                    onSelected: c.onSetRate),
                                IconButton(
                                  onPressed: () => c.onSetMute(!c.isMuted),
                                  icon: Icon(
                                    c.isMuted
                                        ? Icons.volume_off
                                        : Icons.volume_up,
                                    color: primary,
                                    size: 20,
                                  ),
                                ),
                                IconButton(
                                  onPressed: widget.onToggleRotation,
                                  icon: Icon(
                                    widget.isLandscape
                                        ? Icons.screen_lock_portrait
                                        : Icons.screen_lock_landscape,
                                    color: primary,
                                    size: 22,
                                  ),
                                  tooltip: widget.isLandscape ? '切换竖屏' : '切换横屏',
                                ),
                                IconButton(
                                  onPressed: widget.onExit,
                                  icon: const Icon(
                                    Icons.fullscreen_exit,
                                    color: primary,
                                    size: 22,
                                  ),
                                  tooltip: '退出全屏',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── 进度条 ────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.bufferPercent,
    required this.primaryColor,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.dragValue,
  });

  final double progress;
  final int bufferPercent;
  final Color primaryColor;
  final VoidCallback onDragStart;
  final void Function(double) onDragUpdate;
  final void Function(double) onDragEnd;
  final double? dragValue;

  static const double _trackH = 3.0;
  static const double _thumbSz = 12.0;
  static const double _thumbR = _thumbSz / 2;

  @override
  Widget build(BuildContext context) {
    final dp = dragValue ?? progress;
    return LayoutBuilder(builder: (_, c) {
      final w = c.maxWidth;
      final thumbLeft = (dp * w).clamp(_thumbR, w - _thumbR) - _thumbR;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: (d) =>
            onDragUpdate((d.localPosition.dx / w).clamp(0.0, 1.0)),
        onHorizontalDragEnd: (_) => onDragEnd(dragValue ?? progress),
        onTapUp: (d) => onDragEnd((d.localPosition.dx / w).clamp(0.0, 1.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: _thumbSz,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: (_thumbSz - _trackH) / 2,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackH / 2),
                    child: Container(height: _trackH, color: Colors.white24),
                  ),
                ),
                Positioned(
                  top: (_thumbSz - _trackH) / 2,
                  left: 0,
                  width: (bufferPercent / 100).clamp(0.0, 1.0) * w,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackH / 2),
                    child: Container(height: _trackH, color: Colors.white38),
                  ),
                ),
                Positioned(
                  top: (_thumbSz - _trackH) / 2,
                  left: 0,
                  width: (dp * w).clamp(0.0, w),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackH / 2),
                    child: Container(height: _trackH, color: primaryColor),
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  top: 0,
                  child: Container(
                    width: _thumbSz,
                    height: _thumbSz,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black38,
                            blurRadius: 4,
                            offset: Offset(0, 1))
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── 倍速按钮 ──────────────────────────────────────────────────────────────────

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.rate,
    required this.color,
    required this.onSelected,
  });

  final double rate;
  final Color color;
  final void Function(double) onSelected;

  static const _rates = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<double>(
      initialValue: rate,
      onSelected: onSelected,
      itemBuilder: (_) => _rates
          .map((r) => PopupMenuItem(
                value: r,
                child: Text(
                  r == 1.0 ? '正常' : '${r}x',
                  style: TextStyle(
                    fontWeight: r == rate ? FontWeight.bold : FontWeight.normal,
                    color: r == rate ? Theme.of(context).primaryColor : null,
                  ),
                ),
              ))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          rate == 1.0 ? '倍速' : '${rate}x',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ),
    );
  }
}
