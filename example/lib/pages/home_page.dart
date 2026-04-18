import 'package:flutter/material.dart';

import 'single_player_page.dart';
import 'tiktok_page.dart';
import 'feed_list_page.dart';
import 'hero_page.dart';
import 'pool_stress_page.dart';
import 'lifecycle_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _MenuItem(
        icon: Icons.play_circle_filled,
        title: '单播放器 + 控制栏',
        subtitle: '播放/暂停/Seek/倍速/静音/全屏/错误处理',
        color: const Color(0xFF6C63FF),
        page: const SinglePlayerPage(),
      ),
      _MenuItem(
        icon: Icons.vertical_distribute,
        title: '抖音式上下滑动',
        subtitle: '全屏竖向 PageView，自动播放，无缝切换',
        color: const Color(0xFFFF6584),
        page: const TikTokPage(),
      ),
      _MenuItem(
        icon: Icons.view_list_rounded,
        title: 'Feed 流列表',
        subtitle: '滚动列表 + 对象池 LRU + 自动播放可见项',
        color: const Color(0xFF43C6AC),
        page: const FeedListPage(),
      ),
      _MenuItem(
        icon: Icons.open_in_full,
        title: 'Hero 跳转动画',
        subtitle: '列表缩略图 → 全屏播放，连续性过渡',
        color: const Color(0xFFFF9A3C),
        page: const HeroPage(),
      ),
      _MenuItem(
        icon: Icons.memory,
        title: '对象池压力测试',
        subtitle: 'LRU 淘汰 / 复用 / currentPlayer 保护',
        color: const Color(0xFF4ECDC4),
        page: const PoolStressPage(),
      ),
      _MenuItem(
        icon: Icons.phone_android,
        title: '生命周期测试',
        subtitle: '前后台切换自动暂停/恢复 + 引擎切换',
        color: const Color(0xFFA8E6CF),
        page: const LifecyclePage(),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('YuNiPlayer 功能验证',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return _MenuCard(item: item);
        },
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.item});
  final _MenuItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.page),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: item.color, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text(item.subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.page,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget page;
}
