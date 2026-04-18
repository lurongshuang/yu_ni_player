import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater, group, test, setUp, tearDown;
import 'package:yu_ni_player_base/yu_ni_player_base.dart';

// Mock engine for registry tests
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    YuNiPlayerRegistry.instance.clear();
  });

  tearDown(() {
    YuNiPlayerRegistry.instance.clear();
  });

  // Feature: yu-ni-player-multi-package, Property 3: 注册表注册-解析往返
  group('Property 3: 注册表注册-解析往返', () {
    Glados(any.nonEmptyLowercaseLetters).test(
      'register then resolve returns same builder',
      (key) {
        if (key.isEmpty) return;

        final registry = YuNiPlayerRegistry.instance;
        registry.clear();

        EngineBuilder builder = (src) => MockEngine(src);
        registry.register(key, builder);
        expect(registry.resolve(key), same(builder));

        // 覆盖语义：注册两次，resolve 返回最后一个
        EngineBuilder builder2 = (src) => MockEngine(src);
        registry.register(key, builder2);
        expect(registry.resolve(key), same(builder2));

        registry.clear();
      },
    );

    test('registerAll registers all entries', () {
      final registry = YuNiPlayerRegistry.instance;
      EngineBuilder b1 = (src) => MockEngine(src);
      EngineBuilder b2 = (src) => MockEngine(src);

      registry.registerAll({'key1': b1, 'key2': b2});

      expect(registry.resolve('key1'), same(b1));
      expect(registry.resolve('key2'), same(b2));
    });
  });

  // Feature: yu-ni-player-multi-package, Property 4: 注册表 fallback 解析
  group('Property 4: 注册表 fallback 解析', () {
    Glados(any.nonEmptyLowercaseLetters).test(
      'resolve unknown key falls back to defaultKey builder',
      (unknownKey) {
        if (unknownKey.isEmpty) return;
        if (unknownKey == PlatformKey.defaultKey) return;

        final registry = YuNiPlayerRegistry.instance;
        registry.clear();

        // defaultKey 已注册时，未知 key 应 fallback 到 defaultKey
        EngineBuilder defaultBuilder = (src) => MockEngine(src);
        registry.register(PlatformKey.defaultKey, defaultBuilder);

        expect(registry.resolve(unknownKey), same(defaultBuilder));

        registry.clear();

        // defaultKey 未注册时，未知 key 应返回 null
        expect(registry.resolve(unknownKey), isNull);
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 5: 注册表 clear 后全部为空
  group('Property 5: 注册表 clear 后全部为空', () {
    Glados(any.list(any.lowercaseLetters)).test(
      'after clear, all keys resolve to null',
      (keys) {
        final registry = YuNiPlayerRegistry.instance;
        registry.clear();

        // 注册所有非空 key
        final validKeys = keys.where((k) => k.isNotEmpty).toList();
        for (final key in validKeys) {
          registry.register(key, (src) => MockEngine(src));
        }

        registry.clear();

        // clear 后所有 key 均返回 null
        for (final key in validKeys) {
          expect(registry.resolve(key), isNull);
        }
        // defaultKey 也应为 null
        expect(registry.resolve(PlatformKey.defaultKey), isNull);
      },
    );
  });
}
