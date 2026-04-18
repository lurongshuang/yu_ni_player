import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yu_ni_player/yu_ni_player.dart';

import '../data/video_data.dart';

/// 抖音式上下滑动视频页面
class TikTokPage extends StatefulWidget {
  const TikTokPage({super.key});

  @override
  State<TikTokPage> createState() => _TikTokPageState();
}

class _TikTokPageState extends State<TikTokPage> {
  final _pageController = PageController();
  final _pool = YuNiPlayerPool.instance;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playIndex(0));
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    // 暂停当前播放的引擎，并释放所有视频
    for (final v in kTestVideos) {
      final src = YuNiVideoSource(id: 'tiktok-${v.id}', url: v.url);
      // 先暂停再 release（release 会调用 player.release() 停止播放）
      _pool.release(src);
    }
    _pool.currentPlayer = null;
    _pageController.dispose();
    super.dispose();
  }

  YuNiPlayerEngine _engineFor(int index) {
    final v = kTestVideos[index];
    return _pool.acquire(YuNiVideoSource(id: 'tiktok-${v.id}', url: v.url));
  }

  Future<void> _playIndex(int index) async {
    // 暂停其他已在活跃池中的视频
    for (var i = 0; i < kTestVideos.length; i++) {
      if (i == index) continue;
      final v = kTestVideos[i];
      final src = YuNiVideoSource(id: 'tiktok-${v.id}', url: v.url);
      // 只操作已在活跃池中的（不触发新建）
      final engine = _pool.acquire(src);
      if (engine.isPlaying) engine.pause();
    }

    final engine = _engineFor(index);
    _pool.currentPlayer = engine;

    if (!engine.isPrepared) {
      await engine.init(
          config: const YuNiEngineConfig(autoPlay: true, loop: true));
    } else {
      await engine.play();
    }
    if (mounted) setState(() {});
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
    _playIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: _onPageChanged,
            itemCount: kTestVideos.length,
            itemBuilder: (context, index) {
              return _TikTokVideoItem(
                key: ValueKey('tiktok-${kTestVideos[index].id}'),
                video: kTestVideos[index],
                engine: _engineFor(index),
                isActive: index == _currentIndex,
              );
            },
          ),

          // 返回按钮
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 20),
            ),
          ),

          // 标题
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 0,
            right: 0,
            child: const Center(
              child: Text('推荐',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),
          ),

          // 页面指示器
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  kTestVideos.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    width: 3,
                    height: i == _currentIndex ? 20 : 6,
                    decoration: BoxDecoration(
                      color: i == _currentIndex
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TikTokVideoItem extends StatefulWidget {
  const _TikTokVideoItem({
    super.key,
    required this.video,
    required this.engine,
    required this.isActive,
  });

  final VideoItem video;
  final YuNiPlayerEngine engine;
  final bool isActive;

  @override
  State<_TikTokVideoItem> createState() => _TikTokVideoItemState();
}

class _TikTokVideoItemState extends State<_TikTokVideoItem> {
  bool _showPauseIcon = false;

  @override
  void initState() {
    super.initState();
    widget.engine.instanceCode.addListener(_rebuild);
    widget.engine.stateNotifier.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.engine.instanceCode.removeListener(_rebuild);
    widget.engine.stateNotifier.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  void _onTap() {
    if (widget.engine.isPlaying) {
      widget.engine.pause();
      setState(() => _showPauseIcon = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) setState(() => _showPauseIcon = false);
      });
    } else {
      widget.engine.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 直接用 VideoPlayer 铺满，不用 FittedBox 包裹
    // VideoPlayer 本身会按视频宽高比渲染，外层用 ColoredBox 填充黑色背景
    final engineView = widget.engine.buildView();

    return GestureDetector(
      onTap: _onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 黑色背景
          const ColoredBox(color: Colors.black),

          // 视频画面：用 VideoPlayer 直接铺满，cover 效果
          // video_player 的 VideoPlayer 会自动按宽高比居中显示
          // 用 OverflowBox + FittedBox 实现 cover 效果
          LayoutBuilder(
            builder: (ctx, constraints) {
              final screenW = constraints.maxWidth;
              final screenH = constraints.maxHeight;
              final videoAr = widget.engine.videoData.aspectRatio;

              if (videoAr == null || videoAr <= 0) {
                // 视频未初始化，直接显示（VideoPlayer 内部会处理）
                return engineView;
              }

              // 计算 cover 尺寸：保持宽高比，填满屏幕
              double renderW, renderH;
              if (screenW / screenH > videoAr) {
                // 屏幕比视频更宽，以宽度为基准
                renderW = screenW;
                renderH = screenW / videoAr;
              } else {
                // 屏幕比视频更高，以高度为基准
                renderH = screenH;
                renderW = screenH * videoAr;
              }

              return OverflowBox(
                maxWidth: renderW,
                maxHeight: renderH,
                child: SizedBox(
                  width: renderW,
                  height: renderH,
                  child: engineView,
                ),
              );
            },
          ),

          // 加载指示器
          if (widget.engine.state == YuNiPlayerState.loading ||
              widget.engine.state == YuNiPlayerState.buffering)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // 暂停图标
          if (_showPauseIcon)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 40),
              ),
            ),

          // 底部信息栏
          Positioned(
            left: 0,
            right: 60,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, 40, 16, MediaQuery.of(context).padding.bottom + 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black54],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('@${widget.video.author}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(widget.video.title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  // 进度条
                  Builder(builder: (_) {
                    final data = widget.engine.videoData;
                    final progress = data.duration.inMilliseconds > 0
                        ? (data.posMilli ?? 0) / data.duration.inMilliseconds
                        : 0.0;
                    return LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 2,
                    );
                  }),
                ],
              ),
            ),
          ),

          // 右侧操作栏
          Positioned(
            right: 8,
            bottom: MediaQuery.of(context).padding.bottom + 80,
            child: Column(
              children: [
                _SideButton(
                    icon: Icons.favorite_border,
                    label: '12.3万',
                    onTap: () {}),
                const SizedBox(height: 16),
                _SideButton(
                    icon: Icons.comment_outlined,
                    label: '评论',
                    onTap: () {}),
                const SizedBox(height: 16),
                _SideButton(
                    icon: Icons.share_outlined,
                    label: '分享',
                    onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}
