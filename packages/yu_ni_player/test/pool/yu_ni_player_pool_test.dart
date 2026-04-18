import 'package:glados/glados.dart';
import 'package:yu_ni_player/src/core/yu_ni_video_source.dart';
import 'package:yu_ni_player/src/pool/yu_ni_player_pool.dart';
import 'package:yu_ni_player/src/registry/yu_ni_player_registry.dart';

import '../helpers/mock_engine.dart';

/// 创建测试用 YuNiVideoSource（使用唯一 id）
YuNiVideoSource _source(String id) =>
    YuNiVideoSource(id: id, url: 'https://example.com/$id.mp4');

/// 同步重置池和注册表状态（每次属性测试迭代前调用）
///
/// 注意：disposeAll 是异步的，但我们在 setUp 中 await 它。
/// 对于属性测试内部的重置，我们直接调用同步的 configure + clear，
/// 并通过 disposeAll 清空池（在 setUp 中已完成）。
void _resetStateSync() {
  YuNiPlayerRegistry.instance.clear();
  YuNiPlayerRegistry.instance.register('default', (src) => MockEngine(src));
  YuNiPlayerPool.instance.configure(maxActiveCount: 3, maxRecycledCount: 2);
}

void main() {
  setUp(() async {
    await YuNiPlayerPool.instance.disposeAll();
    _resetStateSync();
  });

  // ── 示例测试 ──────────────────────────────────────────────────

  group('示例测试', () {
    test('命中活跃缓存返回同一实例（相同 id acquire 两次）', () {
      final source = _source('video-1');

      final first = YuNiPlayerPool.instance.acquire(source);
      final second = YuNiPlayerPool.instance.acquire(source);

      expect(second, same(first), reason: '相同 id 应命中活跃缓存，返回同一实例');
    });

    test('currentPlayer 不被 LRU 淘汰', () async {
      // 配置最大活跃数为 3
      // acquire 3 个实例，将第一个设为 currentPlayer
      final s1 = _source('lru-1');
      final s2 = _source('lru-2');
      final s3 = _source('lru-3');
      final s4 = _source('lru-4');

      final p1 = YuNiPlayerPool.instance.acquire(s1);
      YuNiPlayerPool.instance.acquire(s2);
      YuNiPlayerPool.instance.acquire(s3);

      // 将 p1 设为 currentPlayer（受 LRU 保护）
      YuNiPlayerPool.instance.currentPlayer = p1;

      // acquire 第 4 个，触发 LRU 淘汰（应淘汰 s2，因为 s1 受保护）
      YuNiPlayerPool.instance.acquire(s4);

      // 等待异步淘汰完成
      await Future<void>.delayed(Duration.zero);

      // p1 仍在活跃池中（未被淘汰）
      expect(
        YuNiPlayerPool.instance.activeCount,
        lessThanOrEqualTo(3),
        reason: '活跃数不应超过 maxActiveCount',
      );

      // 再次 acquire s1 应命中缓存（p1 仍在活跃池）
      final p1Again = YuNiPlayerPool.instance.acquire(s1);
      expect(p1Again, same(p1), reason: 'currentPlayer 不应被 LRU 淘汰');
    });

    test('release 后实例进入回收池（recycledCount 增加）', () async {
      final source = _source('recycle-1');

      YuNiPlayerPool.instance.acquire(source);
      expect(YuNiPlayerPool.instance.recycledCount, equals(0));

      await YuNiPlayerPool.instance.release(source);

      expect(
        YuNiPlayerPool.instance.recycledCount,
        equals(1),
        reason: 'release 后实例应进入回收池',
      );
      expect(
        YuNiPlayerPool.instance.activeCount,
        equals(0),
        reason: 'release 后活跃池应减少',
      );
    });
  });

  // ── Property 5: 活跃数量上限 ──────────────────────────────────
  // **Validates: Requirements 5.1, 12.9**

  group('Property 5: 活跃数量上限', () {
    Glados<int>(any.intInRange(1, 10)).test(
      '任意次 acquire 后 activeCount <= maxActiveCount',
      (n) async {
        // 每次迭代前重置状态
        await YuNiPlayerPool.instance.disposeAll();
        _resetStateSync();

        // acquire n 个不同 id 的实例
        for (var i = 0; i < n; i++) {
          YuNiPlayerPool.instance.acquire(_source('prop5-$i'));
        }

        // 等待异步 LRU 淘汰完成
        await Future<void>.delayed(Duration.zero);

        expect(
          YuNiPlayerPool.instance.activeCount,
          lessThanOrEqualTo(3),
          reason: 'activeCount 不应超过 maxActiveCount=3，当前 n=$n',
        );
      },
    );
  });

  // ── Property 6: 总量上限 ──────────────────────────────────────
  // **Validates: Requirements 5.1, 5.4, 5.5, 12.8**

  group('Property 6: 总量上限', () {
    Glados<int>(any.intInRange(1, 10)).test(
      '任意 acquire/release 序列后 activeCount + recycledCount <= maxActiveCount + maxRecycledCount',
      (n) async {
        // 每次迭代前重置状态
        await YuNiPlayerPool.instance.disposeAll();
        _resetStateSync();

        // acquire n 个不同 id 的实例
        final sources = List.generate(n, (i) => _source('prop6-$i'));
        for (final src in sources) {
          YuNiPlayerPool.instance.acquire(src);
        }

        // release 前半部分
        final releaseCount = n ~/ 2;
        for (var i = 0; i < releaseCount; i++) {
          await YuNiPlayerPool.instance.release(sources[i]);
        }

        // 等待所有异步操作（LRU 淘汰）完成
        await Future<void>.delayed(Duration.zero);

        final total = YuNiPlayerPool.instance.activeCount +
            YuNiPlayerPool.instance.recycledCount;

        expect(
          total,
          lessThanOrEqualTo(5), // maxActiveCount(3) + maxRecycledCount(2)
          reason:
              'activeCount + recycledCount 不应超过 maxActiveCount + maxRecycledCount = 5，'
              '当前 n=$n, active=${YuNiPlayerPool.instance.activeCount}, '
              'recycled=${YuNiPlayerPool.instance.recycledCount}',
        );
      },
    );
  });

  // ── Property 7: disposeAll 后所有实例已销毁 ───────────────────
  // **Validates: Requirements 5.7, 12.10**

  group('Property 7: disposeAll 后所有实例已销毁', () {
    Glados<int>(any.intInRange(1, 10)).test(
      '所有曾 acquire 的引擎 isDisposed == true 在 disposeAll 之后',
      (n) async {
        // 每次迭代前重置状态
        await YuNiPlayerPool.instance.disposeAll();
        _resetStateSync();

        // acquire n 个不同 id 的实例，记录所有引擎
        final engines = <MockEngine>[];
        for (var i = 0; i < n; i++) {
          final engine =
              YuNiPlayerPool.instance.acquire(_source('prop7-$i')) as MockEngine;
          engines.add(engine);
        }

        // 等待异步 LRU 淘汰完成（被淘汰的实例会进入回收池）
        await Future<void>.delayed(Duration.zero);

        // 调用 disposeAll
        await YuNiPlayerPool.instance.disposeAll();

        // 验证所有曾 acquire 的引擎均已销毁
        for (final engine in engines) {
          expect(
            engine.isDisposed,
            isTrue,
            reason: 'disposeAll 后所有引擎的 isDisposed 应为 true',
          );
        }

        // 验证池已清空
        expect(YuNiPlayerPool.instance.activeCount, equals(0));
        expect(YuNiPlayerPool.instance.recycledCount, equals(0));
      },
    );
  });
}
