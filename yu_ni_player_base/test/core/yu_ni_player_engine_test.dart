import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, expectLater, group, test;
import 'package:yu_ni_player_base/yu_ni_player_base.dart';

// Mock engine that captures the actual value passed to performSeek
class MockEngineWithSeekCapture extends YuNiPlayerEngine {
  MockEngineWithSeekCapture(super.source);

  double? lastSeekValue;

  @override
  bool get isPrepared => true;

  @override
  Future<void> performInit() async {}

  @override
  Future<void> performPlay() async {}

  @override
  Future<void> performPause() async {}

  @override
  Future<void> performSeek(double seconds) async {
    lastSeekValue = seconds;
  }

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

  // Feature: yu-ni-player-multi-package, Property 1: Seek clamp 不变量
  group('Property 1: Seek clamp 不变量', () {
    Glados<double>().test(
      'seek clamps input to [0.0, duration.inSeconds]',
      (rawSeconds) {
        final engine = MockEngineWithSeekCapture(
          const YuNiVideoSource(id: 'test', url: 'https://example.com/test.mp4'),
        );
        // Set a known duration of 100 seconds
        engine.videoData.duration = const Duration(seconds: 100);

        engine.seek(rawSeconds);

        final actual = engine.lastSeekValue;
        // If engine is not prepared, seek may not call performSeek
        // but the clamp invariant must hold when it does
        if (actual != null) {
          expect(actual, greaterThanOrEqualTo(0.0));
          expect(actual, lessThanOrEqualTo(100.0));
        }
      },
    );
  });

  // Feature: yu-ni-player-multi-package, Property 2: dispose 后操作幂等性
  group('Property 2: dispose 后操作幂等性', () {
    Glados<int>().test(
      'after dispose, all control methods return without throwing and isDisposed stays true',
      (seed) async {
        final engine = MockEngineWithSeekCapture(
          const YuNiVideoSource(id: 'test2', url: 'https://example.com/test2.mp4'),
        );

        await engine.dispose();
        expect(engine.isDisposed, isTrue);

        // All these must not throw
        await expectLater(engine.play(), completes);
        await expectLater(engine.pause(), completes);
        await expectLater(engine.seek(seed.toDouble()), completes);
        await expectLater(engine.reset(), completes);
        await expectLater(engine.release(), completes);

        // isDisposed must remain true
        expect(engine.isDisposed, isTrue);
      },
    );
  });
}
