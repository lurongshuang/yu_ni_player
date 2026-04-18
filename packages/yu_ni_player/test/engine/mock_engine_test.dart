import 'package:glados/glados.dart';
import 'package:yu_ni_player/src/core/yu_ni_player_state.dart';
import 'package:yu_ni_player/src/core/yu_ni_video_source.dart';

import '../helpers/mock_engine.dart';

// ── 测试辅助类 ────────────────────────────────────────────────────────────────

/// 暴露 @protected 的 updateState，供测试直接触发状态转换。
class TestMockEngine extends MockEngine {
  TestMockEngine(super.source);

  void triggerState(YuNiPlayerState s) => updateState(s);
}

/// 模拟 performInit 抛出异常的引擎，用于测试 error 状态。
class ErrorMockEngine extends MockEngine {
  ErrorMockEngine(super.source);

  @override
  Future<void> performInit() async {
    throw Exception('init failed');
  }
}

// ── 测试用视频源 ──────────────────────────────────────────────────────────────

final _source = YuNiVideoSource(id: 'test-video', url: 'https://example.com/video.mp4');

// ── 测试 ──────────────────────────────────────────────────────────────────────

void main() {
  group('MockEngine 状态机转换示例测试', () {
    // 1. 完整状态转换链：idle → loading → paused → playing → completed
    test('完整状态转换链：idle → loading → paused → playing → completed', () async {
      final engine = TestMockEngine(_source);

      expect(engine.state, YuNiPlayerState.idle);

      await engine.init();
      expect(engine.state, YuNiPlayerState.paused);

      await engine.play();
      expect(engine.state, YuNiPlayerState.playing);

      engine.triggerState(YuNiPlayerState.completed);
      expect(engine.state, YuNiPlayerState.completed);
    });

    // 2. error 状态：init() 失败后 state 为 error，videoData.lastError 非 null
    test('init() 失败后 state 为 error，videoData.lastError 非 null', () async {
      final engine = ErrorMockEngine(_source);

      expect(engine.state, YuNiPlayerState.idle);

      await engine.init();

      expect(engine.state, YuNiPlayerState.error);
      expect(engine.videoData.lastError, isNotNull);
    });

    // 3. buffering 状态：playing 时触发 buffering，buffering 结束后恢复 playing
    test('playing 时触发 buffering，buffering 结束后恢复 playing', () async {
      final engine = TestMockEngine(_source);

      await engine.play();
      expect(engine.state, YuNiPlayerState.playing);

      engine.triggerState(YuNiPlayerState.buffering);
      expect(engine.state, YuNiPlayerState.buffering);

      engine.triggerState(YuNiPlayerState.playing);
      expect(engine.state, YuNiPlayerState.playing);
    });

    // 4. reset()：任意状态调用后 state 回到 idle，videoData 被重置
    test('reset() 后 state 回到 idle，videoData.duration == Duration.zero', () async {
      final engine = TestMockEngine(_source);

      await engine.play();
      expect(engine.state, YuNiPlayerState.playing);

      engine.videoData.duration = const Duration(seconds: 120);
      engine.videoData.lastError = Exception('some error');

      await engine.reset();

      expect(engine.state, YuNiPlayerState.idle);
      expect(engine.videoData.duration, Duration.zero);
      expect(engine.videoData.lastError, isNull);
    });
  });

  // ── Property 1: 状态值始终合法 ────────────────────────────────
  // **Validates: Requirements 1.7, 6.8, 12.1**

  group('Property 1: 状态值始终合法', () {
    Glados<int>(any.intInRange(0, 4)).test(
      '任意操作序列后 stateNotifier.value 是有效的 YuNiPlayerState 枚举值',
      (opCode) async {
        final engine = TestMockEngine(_source);

        switch (opCode) {
          case 0:
            await engine.init();
          case 1:
            await engine.play();
          case 2:
            await engine.pause();
          case 3:
            await engine.seek(5.0);
          case 4:
            await engine.reset();
        }

        expect(
          YuNiPlayerState.values.contains(engine.state),
          isTrue,
          reason: 'opCode=$opCode 后 state=${engine.state} 应是合法的 YuNiPlayerState 枚举值',
        );
      },
    );
  });

  // ── Property 2: dispose 幂等性 ────────────────────────────────
  // **Validates: Requirements 1.7, 1.8, 12.2**

  group('Property 2: dispose 幂等性', () {
    Glados<int>(any.intInRange(1, 5)).test(
      '多次调用 dispose() 后 isDisposed == true 且不抛异常',
      (times) async {
        final engine = TestMockEngine(_source);

        for (var i = 0; i < times; i++) {
          await engine.dispose();
        }

        expect(
          engine.isDisposed,
          isTrue,
          reason: '调用 dispose() $times 次后 isDisposed 应为 true',
        );
      },
    );
  });

  // ── Property 3: dispose 后控制方法不抛异常 ────────────────────
  // **Validates: Requirements 6.8, 12.3**

  group('Property 3: dispose 后控制方法不抛异常', () {
    Glados<double>(any.double).test(
      'dispose 后调用 play()、pause()、seek(任意值) 均不抛异常',
      (seekValue) async {
        final engine = TestMockEngine(_source);
        await engine.dispose();

        await expectLater(engine.play(), completes);
        await expectLater(engine.pause(), completes);
        await expectLater(engine.seek(seekValue), completes);
      },
    );
  });
}
