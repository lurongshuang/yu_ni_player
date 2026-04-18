import 'package:flutter/material.dart';
import 'package:yu_ni_player/yu_ni_player.dart';

import '../data/video_data.dart';

/// Feed 流列表页面
class FeedListPage extends StatefulWidget {
  const FeedListPage({super.key});

  @override
  State<FeedListPage> createState() => _FeedListPageState();
}

class _FeedListPageState extends State<FeedListPage> {
  final _pool = YuNiPlayerPool.instance;
  final _scrollController = ScrollController();
  final _itemKeys = <int, GlobalKey>{};
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _pool.configure(maxActiveCount: 3, maxRecycledCount: 2);
    for (var i = 0; i < kTestVideos.length; i++) {
      _itemKeys[i] = GlobalKey();
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final v in kTestVideos) {
      _pool.release(YuNiVideoSource(id: 'feed-${v.id}', url: v.url));
    }
    super.dispose();
  }

  void _onScroll() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenCenter = screenHeight / 2;
    int? bestIndex;
    double bestDistance = double.infinity;

    for (final entry in _itemKeys.entries) {
      final ctx = entry.value.currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      final itemCenter = pos.dy + box.size.height / 2;
      final distance = (itemCenter - screenCenter).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        bestIndex = entry.key;
      }
    }

    if (bestIndex != null && bestIndex != _playingIndex) {
      _playIndex(bestIndex);
    }
  }

  Future<void> _playIndex(int index) async {
    if (_playingIndex != null && _playingIndex != index) {
      final oldV = kTestVideos[_playingIndex!];
      final oldSrc = YuNiVideoSource(id: 'feed-${oldV.id}', url: oldV.url);
      final oldEngine = _pool.acquire(oldSrc);
      if (oldEngine.isPlaying) await oldEngine.pause();
    }

    setState(() => _playingIndex = index);

    final v = kTestVideos[index];
    final src = YuNiVideoSource(id: 'feed-${v.id}', url: v.url);
    final engine = _pool.acquire(src);
    _pool.currentPlayer = engine;

    if (!engine.isPrepared) {
      await engine.init(
          config: const YuNiEngineConfig(autoPlay: true, loop: true));
    } else if (!engine.isPlaying) {
      await engine.play();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed 流列表'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Text(
                '活跃:${_pool.activeCount} 回收:${_pool.recycledCount}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        controller: _scrollController,
        itemCount: kTestVideos.length,
        itemBuilder: (context, index) {
          final video = kTestVideos[index];
          final src = YuNiVideoSource(id: 'feed-${video.id}', url: video.url);
          final isPlaying = _playingIndex == index;
          return _FeedItem(
            key: _itemKeys[index],
            video: video,
            engine: _pool.acquire(src),
            isPlaying: isPlaying,
            onTap: () => _playIndex(index),
          );
        },
      ),
    );
  }
}

class _FeedItem extends StatelessWidget {
  const _FeedItem({
    super.key,
    required this.video,
    required this.engine,
    required this.isPlaying,
    required this.onTap,
  });

  final VideoItem video;
  final YuNiPlayerEngine engine;
  final bool isPlaying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视频区域
          GestureDetector(
            onTap: onTap,
            child: isPlaying
                ? YuNiPlayer(
                    player: engine,
                    backgroundColor: Colors.black,
                    showDefaultControls: true,
                    aspectRatio: video.aspectRatio,
                  )
                : AspectRatio(
                    aspectRatio: video.aspectRatio,
                    child: Container(
                      color: Colors.grey.shade900,
                      child: Center(
                        child: Icon(
                          Icons.play_circle_outline,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 52,
                        ),
                      ),
                    ),
                  ),
          ),
          // 状态标签（播放中时显示）
          if (isPlaying)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: ValueListenableBuilder(
                valueListenable: engine.stateNotifier,
                builder: (_, state, __) => _StateChip(state: state),
              ),
            ),

          // 视频信息
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    video.author.isNotEmpty
                        ? video.author[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(video.title,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      Text(video.author,
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onTap,
                  icon: Icon(
                    isPlaying ? Icons.pause_circle : Icons.play_circle,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.state});
  final YuNiPlayerState state;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      YuNiPlayerState.idle => ('idle', Colors.grey),
      YuNiPlayerState.loading => ('loading', Colors.blue),
      YuNiPlayerState.playing => ('playing', Colors.green),
      YuNiPlayerState.paused => ('paused', Colors.orange),
      YuNiPlayerState.buffering => ('buffering', Colors.cyan),
      YuNiPlayerState.completed => ('completed', Colors.purple),
      YuNiPlayerState.error => ('error', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}
