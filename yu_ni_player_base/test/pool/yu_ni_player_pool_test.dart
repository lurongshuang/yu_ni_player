import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater, group, test, setUp, tearDown;
import 'package:yu_ni_player_base/yu_ni_player_base.dart';

// Mock engine for pool tests
class MockEngine extends YuNiPlayerEngine {
  MockEngine(super.source);

  @override
  bool get isPrepared => true;

  @override
  Future<void> performInit() async {}

  @override
  Future<void> performPlay() async {}

  @override
  Future<void> performPause() async {}

  @override
  Future<void> performSeek(double seconds) async {}

  @override
  Future<void> performDispose() async {}

  @override
  Future<void> performRelease() async {}

  @override
  Widget buildView() => const SizedBox.shrink();

  @override
  Future<void> setLoop(bool loop) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setMute(bool mute) async {}

  @override
  Future<void> setRate(double rate) async {}

  @override
  Future<void> preload() async {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void onPositionUpdate(void Function(Duration) callback) {}

  @override
  void onBufferUpdate(void Function(int percent) callback) {}

  @override
  void onPrepared(void Function(bool prepared) callback) {}
}

YuNiVideoSource _src(String id) =>
    YuNiVideoSource(id: id, url: 'https://example.com/$id.mp4');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Register MockEngine as the default builder so the pool can create instances
    YuNiPlayerRegistry.instance.clear();
    YuNiPlayerRegistry.instance.register(
      PlatformKey.defaultKey,
      (src) => MockEngine(src),
    );
  });

  tearDown(() async {
    await YuNiPlayerPool.instance.disposeAll();
    YuNiPlayerPool.instance.currentPlayer = null;
    YuNiPlayerPool.instance.configure(maxActiveCount: 3, maxRecycledCount: 2);
    YuNiPlayerRegistry.instance.clear();
  });

  // Feature: yu-ni-player-multi-package, Property 6: 对象池 LRU 缓存命中
  group('Property 6: 对象池 LRU 缓存命中', () {
    Glados(any.nonEmptyLowercaseLetters).test(
      'acquire same source twice returns same instance',
      (id) async {
        if (id.isEmpty) return;

        final pool = YuNiPlayerPool.instance;
        pool.configure(maxActiveCount: 5, maxRecycledCount: 3);

        final source = _src(id);
        final first = pool.acquire(source);
        final second = pool.acquire(source);

        expect(identical(first, second), isTrue);

        await pool.disposeAll();
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 7: LRU 淘汰与 currentPlayer 保护
  group('Property 7: LRU 淘汰与 currentPlayer 保护', () {
    Glados2(any.positiveInt, any.list(any.nonEmptyLowercaseLetters)).test(
      'activeCount never exceeds maxActiveCount and currentPlayer is never evicted',
      (maxActive, sourceIds) async {
        if (maxActive < 1 || maxActive > 5) return;
        if (sourceIds.isEmpty || sourceIds.length > 15) return;
        if (!sourceIds.every((id) => id.isNotEmpty)) return;

        final pool = YuNiPlayerPool.instance;
        pool.configure(maxActiveCount: maxActive, maxRecycledCount: 5);

        YuNiPlayerEngine? protected;
        for (final id in sourceIds) {
          final src = _src(id);
          final engine = pool.acquire(src);
          if (protected == null) {
            protected = engine;
            pool.currentPlayer = engine;
          }
          // Active count must never exceed maxActive
          expect(pool.activeCount, lessThanOrEqualTo(maxActive));
        }

        // currentPlayer must still be in the active pool (not evicted)
        if (protected != null && pool.activeCount > 0) {
          expect(protected.isDisposed, isFalse);
        }

        await pool.disposeAll();
        pool.currentPlayer = null;
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 8: 回收池容量不变量
  group('Property 8: 回收池容量不变量', () {
    Glados2(any.positiveInt, any.list(any.nonEmptyLowercaseLetters)).test(
      'recycledCount never exceeds maxRecycledCount',
      (maxRecycled, sourceIds) async {
        if (maxRecycled < 1 || maxRecycled > 5) return;
        if (sourceIds.isEmpty || sourceIds.length > 10) return;
        if (!sourceIds.every((id) => id.isNotEmpty)) return;

        final pool = YuNiPlayerPool.instance;
        pool.configure(maxActiveCount: 10, maxRecycledCount: maxRecycled);

        // Acquire all sources
        final sources = sourceIds.map(_src).toList();
        for (final src in sources) {
          pool.acquire(src);
        }

        // Release all sources and check recycled count invariant
        for (final src in sources) {
          await pool.release(src);
          expect(pool.recycledCount, lessThanOrEqualTo(maxRecycled));
        }

        await pool.disposeAll();
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 9: release 从活跃池移除
  group('Property 9: release 从活跃池移除', () {
    Glados(any.nonEmptyLowercaseLetters).test(
      'release decreases activeCount by 1',
      (id) async {
        if (id.isEmpty) return;

        final pool = YuNiPlayerPool.instance;
        pool.configure(maxActiveCount: 10, maxRecycledCount: 5);

        final source = _src(id);
        pool.acquire(source);
        final countBefore = pool.activeCount;

        await pool.release(source);

        expect(pool.activeCount, equals(countBefore - 1));

        await pool.disposeAll();
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 10: disposeAll 清空所有池
  group('Property 10: disposeAll 清空所有池', () {
    Glados(any.list(any.lowercaseLetters)).test(
      'after disposeAll, activeCount == 0 and recycledCount == 0',
      (sourceIds) async {
        if (sourceIds.length > 10) return;
        if (!sourceIds.every((id) => id.isNotEmpty)) return;

        final pool = YuNiPlayerPool.instance;
        pool.configure(maxActiveCount: 10, maxRecycledCount: 5);

        // Acquire some sources
        final validIds = sourceIds.where((id) => id.isNotEmpty).toList();
        for (final id in validIds) {
          pool.acquire(_src(id));
        }

        await pool.disposeAll();

        expect(pool.activeCount, equals(0));
        expect(pool.recycledCount, equals(0));
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 11: 回收池 LIFO 复用顺序
  group('Property 11: 回收池 LIFO 复用顺序', () {
    test('acquire after release reuses most recently recycled instance (LIFO)', () async {
      final pool = YuNiPlayerPool.instance;
      pool.configure(maxActiveCount: 10, maxRecycledCount: 5);

      // Acquire and release two distinct sources to populate the recycle pool
      final src1 = _src('lifo-1');
      final src2 = _src('lifo-2');

      final engine1 = pool.acquire(src1);
      final engine2 = pool.acquire(src2);

      // Release in order: engine1 first, engine2 second
      await pool.release(src1); // engine1 goes to recycle pool (index 0)
      await pool.release(src2); // engine2 goes to recycle pool (index 1, most recent)

      expect(pool.recycledCount, equals(2));

      // Acquire a new source — should reuse engine2 (LIFO: last in, first out)
      final src3 = _src('lifo-3');
      final reused = pool.acquire(src3);

      // The reused instance should be engine2 (most recently recycled)
      expect(identical(reused, engine2), isTrue);

      await pool.disposeAll();
    });
  });
}
