import 'package:flutter/material.dart';
import 'package:yu_ni_player_base/yu_ni_player_base.dart';

import '../data/video_data.dart';

/// Hero 动画跳转页面
///
/// 列表缩略图 → 全屏播放，连续性过渡动画
class HeroPage extends StatelessWidget {
  const HeroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hero 跳转动画'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 16 / 9,
        ),
        itemCount: kTestVideos.length,
        itemBuilder: (context, index) {
          final video = kTestVideos[index];
          return _VideoThumbnail(video: video, index: index);
        },
      ),
    );
  }
}

class _VideoThumbnail extends StatelessWidget {
  const _VideoThumbnail({required this.video, required this.index});
  final VideoItem video;
  final int index;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'video-hero-${video.id}';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            reverseTransitionDuration: const Duration(milliseconds: 350),
            pageBuilder: (ctx, animation, secondaryAnimation) =>
                _HeroPlayerPage(video: video, heroTag: heroTag),
            transitionsBuilder:
                (ctx, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      },
      child: Hero(
        tag: heroTag,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 封面占位（实际项目中替换为真实封面图）
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _indexColor(index).withValues(alpha: 0.8),
                        _indexColor(index + 3).withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      color: Colors.white.withValues(alpha: 0.8),
                      size: 40,
                    ),
                  ),
                ),
              ),
              // 标题
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _indexColor(int i) {
    const colors = [
      Color(0xFF6C63FF),
      Color(0xFFFF6584),
      Color(0xFF43C6AC),
      Color(0xFFFF9A3C),
      Color(0xFF4ECDC4),
      Color(0xFFA8E6CF),
      Color(0xFFFFD93D),
      Color(0xFF6BCB77),
    ];
    return colors[i % colors.length];
  }
}

/// Hero 目标页面：全屏播放器
class _HeroPlayerPage extends StatefulWidget {
  const _HeroPlayerPage({required this.video, required this.heroTag});
  final VideoItem video;
  final String heroTag;

  @override
  State<_HeroPlayerPage> createState() => _HeroPlayerPageState();
}

class _HeroPlayerPageState extends State<_HeroPlayerPage> {
  late YuNiPlayerEngine _engine;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _engine = YuNiPlayerPool.instance.acquire(
      YuNiVideoSource(id: 'hero-${widget.video.id}', url: widget.video.url),
    );
    YuNiPlayerPool.instance.currentPlayer = _engine;
    _initAndPlay();
  }

  Future<void> _initAndPlay() async {
    await _engine.init(config: const YuNiEngineConfig(autoPlay: true));
    if (mounted) setState(() => _ready = true);
  }

  @override
  void dispose() {
    YuNiPlayerPool.instance.release(
      YuNiVideoSource(id: 'hero-${widget.video.id}', url: widget.video.url),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Hero 动画包裹播放器
          Center(
            child: Hero(
              tag: widget.heroTag,
              child: AspectRatio(
                aspectRatio: widget.video.aspectRatio,
                child: _ready
                    ? YuNiPlayer(
                        player: _engine,
                        backgroundColor: Colors.black,
                        showDefaultControls: true,
                        allowFullscreen: true,
                      )
                    : Container(
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Colors.white),
                        ),
                      ),
              ),
            ),
          ),

          // 顶部信息栏
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.white, size: 20),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.video.title,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(widget.video.author,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
