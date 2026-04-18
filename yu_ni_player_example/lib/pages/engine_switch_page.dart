import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_media_kit/yu_ni_player_media_kit.dart';
import 'package:yu_ni_player_tx_player/yu_ni_player_tx_player.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

import '../data/video_data.dart';

// ── 引擎类型枚举 ──────────────────────────────────────────────────────────────

enum EngineType {
  videoPlayerKit('VideoPlayerKit', 'Flutter 官方 video_player'),
  mediaKit('MediaKit', '开源 media_kit（全平台）'),
  txPlayer('TXPlayer', '腾讯 super_player（仅 Android/iOS）');

  const EngineType(this.label, this.description);
  final String label;
  final String description;
}

// ── 页面 ──────────────────────────────────────────────────────────────────────

class EngineSwitchPage extends StatefulWidget {
  const EngineSwitchPage({super.key});

  @override
  State<EngineSwitchPage> createState() => _EngineSwitchPageState();
}

class _EngineSwitchPageState extends State<EngineSwitchPage> {
  // 当前选中的视频（可切换）
  int _videoIndex = 0;

  // 当前引擎类型
  EngineType _currentType = EngineType.videoPlayerKit;

  // 当前引擎实例
  YuNiPlayerEngine? _engine;

  // 切换时记录的播放位置（秒）
  double _savedPosition = 0;

  // 是否正在切换引擎
  bool _switching = false;

  // 日志
  final List<_LogEntry> _logs = [];

  // TXPlayer 是否可用（仅 Android/iOS）
  bool get _txPlayerAvailable =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    _createEngine(_currentType, seekTo: 0);
  }

  @override
  void dispose() {
    _engine?.dispose();
    super.dispose();
  }

  // ── 引擎工厂 ──────────────────────────────────────────────────────────────

  YuNiPlayerEngine _buildEngine(EngineType type, YuNiVideoSource source) {
    switch (type) {
      case EngineType.videoPlayerKit:
        return VideoPlayerKitEngine(source);
      case EngineType.mediaKit:
        return MediaKitEngine(source);
      case EngineType.txPlayer:
        return TXPlayerEngine(source);
    }
  }

  // ── 创建并初始化引擎 ──────────────────────────────────────────────────────

  Future<void> _createEngine(EngineType type, {required double seekTo}) async {
    final video = kTestVideos[_videoIndex];
    final source = YuNiVideoSource(id: '${video.id}_${type.name}', url: video.url);

    final engine = _buildEngine(type, source);
    setState(() {
      _engine = engine;
      _switching = false;
    });

    _addLog('▶ 初始化 ${type.label}', LogLevel.info);

    try {
      await engine.init(config: const YuNiEngineConfig(autoPlay: false));

      if (!mounted) return;

      if (seekTo > 0) {
        _addLog('⏩ Seek 到 ${seekTo.toStringAsFixed(1)}s', LogLevel.info);
        await engine.seek(seekTo, autoPlay: true);
      } else {
        await engine.play();
      }

      _addLog('✅ ${type.label} 就绪', LogLevel.success);
    } catch (e) {
      _addLog('❌ ${type.label} 初始化失败: $e', LogLevel.error);
    }

    if (mounted) setState(() {});
  }

  // ── 切换引擎 ──────────────────────────────────────────────────────────────

  Future<void> _switchEngine(EngineType newType) async {
    if (newType == _currentType || _switching) return;

    if (newType == EngineType.txPlayer && !_txPlayerAvailable) {
      _showSnackBar('TXPlayer 仅支持 Android 和 iOS');
      return;
    }

    setState(() => _switching = true);

    // 1. 记录当前播放位置
    final posMs = _engine?.videoData.posMilli ?? 0;
    _savedPosition = posMs / 1000.0;
    _addLog('📍 保存播放位置: ${_savedPosition.toStringAsFixed(1)}s', LogLevel.info);

    // 2. 销毁旧引擎
    final oldEngine = _engine;
    setState(() => _engine = null);
    _addLog('🗑 销毁 ${_currentType.label}', LogLevel.info);
    await oldEngine?.dispose();

    // 3. 更新类型
    setState(() => _currentType = newType);

    // 4. 创建新引擎，从保存位置继续
    await _createEngine(newType, seekTo: _savedPosition);
  }

  // ── 切换视频 ──────────────────────────────────────────────────────────────

  Future<void> _switchVideo(int index) async {
    if (index == _videoIndex) return;

    setState(() {
      _videoIndex = index;
      _switching = true;
    });

    _addLog('🎬 切换视频: ${kTestVideos[index].title}', LogLevel.info);

    final oldEngine = _engine;
    setState(() => _engine = null);
    await oldEngine?.dispose();

    await _createEngine(_currentType, seekTo: 0);
  }

  // ── 日志 ──────────────────────────────────────────────────────────────────

  void _addLog(String message, LogLevel level) {
    if (!mounted) return;
    setState(() {
      _logs.insert(0, _LogEntry(message: message, level: level,
          time: DateTime.now()));
      if (_logs.length > 30) _logs.removeLast();
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final engine = _engine;
    final video = kTestVideos[_videoIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('引擎切换对比'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: '清空日志',
            onPressed: () => setState(() => _logs.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── 播放器 ──────────────────────────────────────────────
          _buildPlayer(engine),

          // ── 引擎选择器 ──────────────────────────────────────────
          _buildEngineSelector(),

          // ── 视频选择器 ──────────────────────────────────────────
          _buildVideoSelector(video),

          // ── 状态栏 ──────────────────────────────────────────────
          _buildStatusBar(engine),

          // ── 日志 ────────────────────────────────────────────────
          Expanded(child: _buildLog()),
        ],
      ),
    );
  }

  Widget _buildPlayer(YuNiPlayerEngine? engine) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (engine != null)
            YuNiPlayer(
              key: ValueKey(engine.hashCode),
              player: engine,
              backgroundColor: Colors.black,
              showDefaultControls: true,
              allowFullscreen: true,
            ),
          if (_switching)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 12),
                    Text(
                      '切换到 ${_currentType.label}...',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEngineSelector() {
    return Container(
      color: const Color(0xFF1A1A2E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('选择引擎',
              style: TextStyle(color: Colors.white70, fontSize: 11,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: EngineType.values.map((type) {
              final isSelected = type == _currentType;
              final isDisabled = type == EngineType.txPlayer && !_txPlayerAvailable;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: _EngineChip(
                    label: type.label,
                    description: type.description,
                    isSelected: isSelected,
                    isDisabled: isDisabled || _switching,
                    onTap: () => _switchEngine(type),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSelector(VideoItem video) {
    return Container(
      color: const Color(0xFF16213E),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text('视频：',
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              video.title,
              style: const TextStyle(color: Colors.white,
                  fontSize: 12, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          // 上一个
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 20),
            onPressed: _videoIndex > 0
                ? () => _switchVideo(_videoIndex - 1)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text('${_videoIndex + 1}/${kTestVideos.length}',
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          // 下一个
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white70, size: 20),
            onPressed: _videoIndex < kTestVideos.length - 1
                ? () => _switchVideo(_videoIndex + 1)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(YuNiPlayerEngine? engine) {
    final state = engine?.state ?? YuNiPlayerState.idle;
    final posMs = engine?.videoData.posMilli ?? 0;
    final durMs = engine?.videoData.duration.inMilliseconds ?? 0;
    final bufPct = engine?.videoData.bufferPercent ?? 0;
    final ar = engine?.videoData.aspectRatio;

    String fmt(int ms) {
      final s = ms ~/ 1000;
      final m = s ~/ 60;
      return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    }

    return Container(
      color: const Color(0xFF0F3460),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _StatusBadge(state: state),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_currentType.label}  •  ${fmt(posMs)} / ${fmt(durMs)}',
                  style: const TextStyle(color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '缓冲 $bufPct%  •  宽高比 ${ar?.toStringAsFixed(2) ?? '--'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLog() {
    return Container(
      color: const Color(0xFF0A0A1A),
      child: _logs.isEmpty
          ? const Center(
              child: Text('切换引擎后这里会显示日志',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _logs.length,
              itemBuilder: (_, i) {
                final log = _logs[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log.time.hour.toString().padLeft(2, '0')}:'
                        '${log.time.minute.toString().padLeft(2, '0')}:'
                        '${log.time.second.toString().padLeft(2, '0')} ',
                        style: const TextStyle(
                            color: Colors.white24, fontSize: 10,
                            fontFamily: 'monospace'),
                      ),
                      Expanded(
                        child: Text(
                          log.message,
                          style: TextStyle(
                            color: log.level.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ── 引擎 Chip ─────────────────────────────────────────────────────────────────

class _EngineChip extends StatelessWidget {
  const _EngineChip({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? const Color(0xFF6C63FF)
        : isDisabled
            ? Colors.white10
            : Colors.white12;
    final textColor = isDisabled ? Colors.white24 : Colors.white;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: Colors.white30, width: 1)
              : null,
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(description,
                style: TextStyle(color: textColor.withValues(alpha: 0.6),
                    fontSize: 9),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

// ── 状态徽章 ──────────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});
  final YuNiPlayerState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      YuNiPlayerState.idle => ('IDLE', Colors.grey),
      YuNiPlayerState.loading => ('LOADING', Colors.orange),
      YuNiPlayerState.playing => ('PLAYING', Colors.green),
      YuNiPlayerState.paused => ('PAUSED', Colors.blue),
      YuNiPlayerState.buffering => ('BUFFERING', Colors.amber),
      YuNiPlayerState.completed => ('DONE', Colors.teal),
      YuNiPlayerState.error => ('ERROR', Colors.red),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ── 日志模型 ──────────────────────────────────────────────────────────────────

enum LogLevel {
  info(Colors.white70),
  success(Colors.greenAccent),
  error(Colors.redAccent);

  const LogLevel(this.color);
  final Color color;
}

class _LogEntry {
  const _LogEntry({
    required this.message,
    required this.level,
    required this.time,
  });
  final String message;
  final LogLevel level;
  final DateTime time;
}
