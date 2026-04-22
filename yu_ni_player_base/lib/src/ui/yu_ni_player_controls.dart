import 'dart:async';

import 'package:flutter/material.dart';

import '../core/yu_ni_player_state.dart';

/// 控制栏构建器类型
///
/// 接收 [YuNiControlsContext] 提供的播放器状态和操作方法，
/// 返回自定义控制栏 Widget。
typedef YuNiControlsBuilder = Widget Function(
  BuildContext context,
  YuNiControlsContext controls,
);

/// 控制栏上下文
///
/// 封装播放器当前状态和所有可用操作，传递给 [YuNiControlsBuilder]。
/// 使用者通过此对象构建完全自定义的控制栏，无需直接操作引擎。
class YuNiControlsContext {
  const YuNiControlsContext({
    required this.state,
    required this.position,
    required this.duration,
    required this.bufferPercent,
    required this.isFullscreen,
    required this.onPlay,
    required this.onPause,
    required this.onSeek,
    required this.onToggleFullscreen,
    required this.onSetRate,
    required this.onSetMute,
    required this.isMuted,
    required this.rate,
  });

  /// 当前播放状态
  final YuNiPlayerState state;

  /// 当前播放位置
  final Duration position;

  /// 视频总时长
  final Duration duration;

  /// 缓冲进度（0–100）
  final int bufferPercent;

  /// 是否全屏
  final bool isFullscreen;

  /// 是否静音
  final bool isMuted;

  /// 当前播放速率
  final double rate;

  /// 播放
  final VoidCallback onPlay;

  /// 暂停
  final VoidCallback onPause;

  /// Seek（秒）
  final void Function(double seconds) onSeek;

  /// 切换全屏
  final VoidCallback onToggleFullscreen;

  /// 设置播放速率
  final void Function(double rate) onSetRate;

  /// 设置静音
  final void Function(bool mute) onSetMute;

  bool get isPlaying => state == YuNiPlayerState.playing;

  bool get isLoading =>
      state == YuNiPlayerState.loading || state == YuNiPlayerState.buffering;

  bool get isError => state == YuNiPlayerState.error;

  bool get isCompleted => state == YuNiPlayerState.completed;

  /// 进度百分比（0.0 ~ 1.0）
  double get progress {
    if (duration.inMilliseconds == 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }
}

/// 默认控制栏 Widget
///
/// 提供开箱即用的播放控制栏，支持：
/// - 播放/暂停按钮
/// - 进度条（含缓冲进度）
/// - 时间显示
/// - 全屏切换
/// - 倍速选择
/// - 静音切换
///
/// 通过 [YuNiPlayer.controlsBuilder] 可完全替换为自定义实现。
class YuNiDefaultControls extends StatefulWidget {
  const YuNiDefaultControls({
    super.key,
    required this.controls,
    this.autoHideDelay = const Duration(seconds: 3),
    this.showRateButton = true,
    this.showMuteButton = true,
    this.showFullscreenButton = true,
    this.primaryColor,
    this.backgroundColor,
    this.extraActions,
    this.padding,
  });

  final YuNiControlsContext controls;

  /// 控制栏自动隐藏延迟（默认 3 秒）
  final Duration autoHideDelay;

  /// 是否显示倍速按钮
  final bool showRateButton;

  /// 是否显示静音按钮
  final bool showMuteButton;

  /// 是否显示全屏按钮
  final bool showFullscreenButton;

  /// 主色调（进度条、按钮颜色）
  final Color? primaryColor;

  /// 控制栏背景色
  final Color? backgroundColor;

  /// 额外添加到底部控制栏右侧的组件列表（渲染在 Spacer 之后，RateButton 之前）
  final List<Widget>? extraActions;

  /// 控制栏边距，默认 EdgeInsets.fromLTRB(8, 24, 8, 8)
  final EdgeInsetsGeometry? padding;

  @override
  State<YuNiDefaultControls> createState() => _YuNiDefaultControlsState();
}

class _YuNiDefaultControlsState extends State<YuNiDefaultControls>
    with SingleTickerProviderStateMixin {
  bool _visible = true;
  Timer? _hideTimer;
  bool _dragging = false;
  double _dragValue = 0;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _fadeAnimation = _fadeController;
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!widget.controls.isPlaying) return;
    _hideTimer = Timer(widget.autoHideDelay, () {
      if (mounted && !_dragging) {
        _fadeController.reverse();
        setState(() => _visible = false);
      }
    });
  }

  void _show() {
    _hideTimer?.cancel();
    _fadeController.forward();
    setState(() => _visible = true);
    _scheduleHide();
  }

  void _toggleVisibility() {
    if (_visible) {
      _hideTimer?.cancel();
      _fadeController.reverse();
      setState(() => _visible = false);
    } else {
      _show();
    }
  }

  @override
  void didUpdateWidget(covariant YuNiDefaultControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.controls.isPlaying && !_visible) {
      _show();
    }
    if (widget.controls.isPlaying &&
        oldWidget.controls.state != widget.controls.state) {
      _scheduleHide();
    }
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controls;
    final primary = widget.primaryColor ?? Colors.white;
    final bg = widget.backgroundColor ?? const Color(0x99000000);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleVisibility,
      child: Stack(
        children: [
          if (c.isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
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
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.replay, color: Colors.white, size: 36),
                ),
              ),
            ),
          FadeTransition(
            opacity: _fadeAnimation,
            child: _visible
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              bg,
                            ],
                          ),
                        ),
                        padding: widget.padding ?? const EdgeInsets.fromLTRB(8, 24, 8, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ProgressBar(
                              progress: c.progress,
                              bufferPercent: c.bufferPercent,
                              duration: c.duration,
                              primaryColor: primary,
                              onDragStart: () {
                                _dragging = true;
                                _dragValue = c.progress;
                                _hideTimer?.cancel();
                              },
                              onDragUpdate: (v) {
                                setState(() => _dragValue = v);
                              },
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
                                  '${_formatDuration(c.position)} / ${_formatDuration(c.duration)}',
                                  style:
                                      TextStyle(color: primary, fontSize: 12),
                                ),
                                const Spacer(),
                                if (widget.extraActions != null)
                                  ...widget.extraActions!,
                                if (widget.showRateButton)
                                  _RateButton(
                                    rate: c.rate,
                                    color: primary,
                                    onSelected: c.onSetRate,
                                  ),
                                if (widget.showMuteButton)
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
                                if (widget.showFullscreenButton)
                                  IconButton(
                                    onPressed: c.onToggleFullscreen,
                                    icon: Icon(
                                      c.isFullscreen
                                          ? Icons.fullscreen_exit
                                          : Icons.fullscreen,
                                      color: primary,
                                      size: 22,
                                    ),
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

/// 进度条组件（含缓冲进度 + 拖拽）
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.progress,
    required this.bufferPercent,
    required this.duration,
    required this.primaryColor,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    this.dragValue,
  });

  final double progress;
  final int bufferPercent;
  final Duration duration;
  final Color primaryColor;
  final VoidCallback onDragStart;
  final void Function(double) onDragUpdate;
  final void Function(double) onDragEnd;
  final double? dragValue;

  static const double _trackHeight = 3.0;
  static const double _thumbSize = 12.0;
  static const double _thumbRadius = _thumbSize / 2;

  @override
  Widget build(BuildContext context) {
    final displayProgress = dragValue ?? progress;

    return LayoutBuilder(builder: (context, constraints) {
      final trackWidth = constraints.maxWidth;
      final thumbCenterX = (displayProgress * trackWidth)
          .clamp(_thumbRadius, trackWidth - _thumbRadius);
      final thumbLeft = thumbCenterX - _thumbRadius;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => onDragStart(),
        onHorizontalDragUpdate: (d) {
          final v = (d.localPosition.dx / trackWidth).clamp(0.0, 1.0);
          onDragUpdate(v);
        },
        onHorizontalDragEnd: (_) {
          final v = dragValue ?? progress;
          onDragEnd(v);
        },
        onTapUp: (d) {
          final v = (d.localPosition.dx / trackWidth).clamp(0.0, 1.0);
          onDragEnd(v);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SizedBox(
            height: _thumbSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: (_thumbSize - _trackHeight) / 2,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    child: Container(
                      height: _trackHeight,
                      color: Colors.white24,
                    ),
                  ),
                ),
                Positioned(
                  top: (_thumbSize - _trackHeight) / 2,
                  left: 0,
                  width: (bufferPercent / 100).clamp(0.0, 1.0) * trackWidth,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    child: Container(
                      height: _trackHeight,
                      color: Colors.white38,
                    ),
                  ),
                ),
                Positioned(
                  top: (_thumbSize - _trackHeight) / 2,
                  left: 0,
                  width: (displayProgress * trackWidth).clamp(0.0, trackWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_trackHeight / 2),
                    child: Container(
                      height: _trackHeight,
                      color: primaryColor,
                    ),
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  top: 0,
                  child: Container(
                    width: _thumbSize,
                    height: _thumbSize,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
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

/// 倍速选择按钮
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
