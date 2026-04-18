import 'package:glados/glados.dart';
import 'package:yu_ni_player/src/core/yu_ni_player_engine.dart';
import 'package:yu_ni_player/src/core/yu_ni_video_source.dart';
import 'package:yu_ni_player/src/registry/yu_ni_player_registry.dart';

/// 用于测试的虚拟 builder，不需要真正创建引擎
EngineBuilder _makeBuilder(int id) =>
    (YuNiVideoSource src) => throw UnimplementedError('builder $id');

void main() {
  setUp(() {
    YuNiPlayerRegistry.instance.clear();
  });

  group('YuNiPlayerRegistry', () {
    // ── 示例测试 ──────────────────────────────────────────────────

    test('无注册时 resolve 返回 null', () {
      expect(YuNiPlayerRegistry.instance.resolve('android'), isNull);
    });

    test('registerAll 批量注册后可以 resolve 到对应 builder', () {
      final builderA = _makeBuilder(1);
      final builderB = _makeBuilder(2);

      YuNiPlayerRegistry.instance.registerAll({
        'android': builderA,
        'ios': builderB,
      });

      expect(YuNiPlayerRegistry.instance.resolve('android'), same(builderA));
      expect(YuNiPlayerRegistry.instance.resolve('ios'), same(builderB));
    });

    test('clear() 后 resolve 返回 null', () {
      YuNiPlayerRegistry.instance.register('android', _makeBuilder(1));
      YuNiPlayerRegistry.instance.clear();

      expect(YuNiPlayerRegistry.instance.resolve('android'), isNull);
    });

    // ── Property 3: 注册表覆盖属性 ────────────────────────────────
    // **Validates: Requirements 2.2, 12.6**

    group('Property 3: 注册表覆盖属性', () {
      Glados<String>(any.nonEmptyLetterOrDigits).test(
        '同一 key 注册两次，第二个 builder 生效',
        (platformKey) {

          final builder1 = _makeBuilder(1);
          final builder2 = _makeBuilder(2);

          YuNiPlayerRegistry.instance.register(platformKey, builder1);
          YuNiPlayerRegistry.instance.register(platformKey, builder2);

          expect(
            YuNiPlayerRegistry.instance.resolve(platformKey),
            same(builder2),
            reason: '第二次注册应覆盖第一次，resolve 应返回 builder2',
          );
        },
      );
    });

    // ── Property 4: 注册表轮询（round-trip）────────────────────────
    // **Validates: Requirements 2.3, 12.7**

    group('Property 4: 注册表轮询（round-trip）', () {
      Glados<String>(any.nonEmptyLetterOrDigits).test(
        '注册后 resolve 返回同一 builder',
        (platformKey) {

          final builder = _makeBuilder(42);

          YuNiPlayerRegistry.instance.register(platformKey, builder);

          expect(
            YuNiPlayerRegistry.instance.resolve(platformKey),
            same(builder),
            reason: 'resolve 应返回注册时传入的同一 builder 实例',
          );
        },
      );
    });
  });
}
