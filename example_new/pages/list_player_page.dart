import 'package:flutter/material.dart';
import 'package:yu_ni_player/yu_ni_player.dart';

// 多个公开测试视频
const _videos = [
  (
    id: 'v1',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
    title: 'Big Buck Bunny'
  ),
  (
    id: 'v2',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    title: 'Elephants Dream'
  ),
  (
    id: 'v3',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
    title: 'For Bigger Blazes'
  ),
  (
    id: 'v4',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
    title: 'For Bigger Escapes'
  ),
  (
    id: 'v5',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
    title: 'For Bigger Fun'
  ),
  (
    id: 'v6',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4',
    title: 'For Bigger Joyrides'
  ),
  (
    id: 'v7',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackOnStreetAndDirt.mp4',
    title: 'Subaru Outback'
  ),
  (
    id: 'v8',
    url:
        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
    title: 'Tears of Steel'
  ),
];

class ListPlayerPage extends StatefulWidget {
  const ListPlayerPage({super.key});

  @override
  State<ListPlayerPage> createState() => _ListPlayerPageState();
}

class _ListPlayerPageState extends State<ListPlayerPage> {
  final _pool = YuNiPlayerPool.instance;
  int? _playingIndex;

  @override
  void dispose() {
    // 释放本页面用到的所有视频
    for (final v in _videos) {
      _pool.release(YuNiVideoSource(id: v.id, url: v.url));
    }
    super.dispose();
  }

  void _onTap(int index) async {
    final v = _videos[index];
    final source = YuNiVideoSource(id: v.id, url: v.url);
    final engine = _pool.acquire(source);
    _pool.currentPlayer = engine;

    setState(() => _playingIndex = index);

    if (!engine.isPrepared) {
      await engine.init();
    }
    await engine.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('列表播放测试'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // 显示对象池状态
          ValueListenableBuilder(
            valueListenable: ValueNotifier(0),
            builder: (_, __, ___) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Text(
                    '活跃:${_pool.activeCount} 回收:${_pool.recycledCount}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 对象池状态面板
          _PoolStatusPanel(pool: _pool),

          // 视频列表
          Expanded(
            child: ListView.builder(
              itemCount: _videos.length,
              itemBuilder: (context, index) {
                final v = _videos[index];
                final isPlaying = _playingIndex == index;
                final source = YuNiVideoSource(id: v.id, url: v.url);

                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    children: [
                      // 视频播放区域
                      if (isPlaying)
                        SizedBox(
                          height: 200,
                          child: Builder(builder: (ctx) {
                            final engine = _pool.acquire(source);
                            return YuNiPlayer(
                              player: engine,
                              backgroundColor: Colors.black,
                              loadingBuilder: (ctx) => const Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white),
                              ),
                            );
                          }),
                        ),

                      ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPlaying
                              ? Colors.green.shade100
                              : Colors.grey.shade200,
                          child: Icon(
                            isPlaying ? Icons.pause : Icons.play_arrow,
                            color: isPlaying ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(v.title),
                        subtitle: Text('ID: ${v.id}',
                            style: const TextStyle(fontSize: 11)),
                        trailing: _PoolBadge(
                            pool: _pool, sourceId: v.id, isPlaying: isPlaying),
                        onTap: () => _onTap(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolStatusPanel extends StatefulWidget {
  const _PoolStatusPanel({required this.pool});
  final YuNiPlayerPool pool;

  @override
  State<_PoolStatusPanel> createState() => _PoolStatusPanelState();
}

class _PoolStatusPanelState extends State<_PoolStatusPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          _StatBox(
              label: '活跃池',
              value: '${widget.pool.activeCount}/3',
              color: Colors.blue),
          const SizedBox(width: 12),
          _StatBox(
              label: '回收池',
              value: '${widget.pool.recycledCount}/2',
              color: Colors.orange),
          const Spacer(),
          TextButton.icon(
            onPressed: () {
              setState(() {});
            },
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('刷新'),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: color, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 10, color: color)),
        ],
      ),
    );
  }
}

class _PoolBadge extends StatelessWidget {
  const _PoolBadge(
      {required this.pool,
      required this.sourceId,
      required this.isPlaying});
  final YuNiPlayerPool pool;
  final String sourceId;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    if (isPlaying) {
      return const Chip(
        label: Text('播放中', style: TextStyle(fontSize: 10)),
        backgroundColor: Colors.green,
        labelStyle: TextStyle(color: Colors.white),
        padding: EdgeInsets.zero,
      );
    }
    return const SizedBox.shrink();
  }
}
