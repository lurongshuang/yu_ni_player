import 'package:flutter/material.dart';
import 'package:yu_ni_player_base/yu_ni_player_base.dart';
import 'package:yu_ni_player_video_player_kit/yu_ni_player_video_player_kit.dart';

import '../data/video_data.dart';

class SinglePlayerPage extends StatefulWidget {
  const SinglePlayerPage({super.key});

  @override
  State<SinglePlayerPage> createState() => _SinglePlayerPageState();
}

class _SinglePlayerPageState extends State<SinglePlayerPage> {
  late YuNiPlayerEngine _engine;
  final _playerKey = GlobalKey();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final video = kTestVideos.first;
    _engine = VideoPlayerKitEngine(
      YuNiVideoSource(id: video.id, url: video.url),
    );
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _engine.init(config: const YuNiEngineConfig(autoPlay: true));
    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('单播放器 + 控制栏'),
      ),
      body: Column(
        children: [
          // ── 播放器区域 ──────────────────────────────────────────
          YuNiPlayer(
            key: _playerKey,
            player: _engine,
            backgroundColor: Colors.black,
            showDefaultControls: true,
            allowFullscreen: true,
            onFullscreenChanged: (isFullscreen) {
              // 全屏状态变化回调
            },
          ),

          // ── 视频信息 ────────────────────────────────────────────
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kTestVideos.first.title,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(kTestVideos.first.author,
                        style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
                    const SizedBox(height: 16),

                    // 初始化按钮
                    if (!_initialized)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _init,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('初始化并播放'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),

                    if (_initialized) ...[
                      const Text('控制栏功能说明',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      _FeatureItem(
                          icon: Icons.touch_app,
                          text: '点击视频区域 → 显示/隐藏控制栏'),
                      _FeatureItem(
                          icon: Icons.play_arrow,
                          text: '播放/暂停按钮'),
                      _FeatureItem(
                          icon: Icons.linear_scale,
                          text: '进度条拖拽 Seek（含缓冲进度显示）'),
                      _FeatureItem(
                          icon: Icons.speed,
                          text: '倍速选择（0.5x ~ 2.0x）'),
                      _FeatureItem(
                          icon: Icons.volume_off,
                          text: '静音切换'),
                      _FeatureItem(
                          icon: Icons.fullscreen,
                          text: '全屏切换（横屏锁定）'),
                      _FeatureItem(
                          icon: Icons.replay,
                          text: '播放完成后点击重播按钮'),

                      const SizedBox(height: 16),
                      const Text('自定义控制栏示例',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      const Text(
                        '通过 controlsBuilder 参数可完全替换控制栏：\n\n'
                        'YuNiPlayer(\n'
                        '  player: engine,\n'
                        '  controlsBuilder: (ctx, controls) {\n'
                        '    return MyCustomControls(controls: controls);\n'
                        '  },\n'
                        ')',
                        style: TextStyle(
                            fontFamily: 'monospace', fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
