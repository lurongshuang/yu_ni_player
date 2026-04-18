import 'package:glados/glados.dart';
import 'package:yu_ni_player/src/core/yu_ni_engine_config.dart';

import '../helpers/arbitraries.dart';

void main() {
  group('YuNiEngineConfig', () {
    group('constructor', () {
      test('creates with default values', () {
        const config = YuNiEngineConfig();
        expect(config.loop, isFalse);
        expect(config.mute, isFalse);
        expect(config.autoPlay, isFalse);
        expect(config.speed, equals(1.0));
        expect(config.hardwareAcceleration, isTrue);
        expect(config.headers, isEmpty);
      });

      test('throws AssertionError when speed < 0.25', () {
        expect(
          () => YuNiEngineConfig(speed: 0.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws AssertionError when speed > 4.0', () {
        expect(
          () => YuNiEngineConfig(speed: 5.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts speed at lower boundary 0.25', () {
        expect(
          () => const YuNiEngineConfig(speed: 0.25),
          returnsNormally,
        );
      });

      test('accepts speed at upper boundary 4.0', () {
        expect(
          () => const YuNiEngineConfig(speed: 4.0),
          returnsNormally,
        );
      });
    });

    group('Property 9: copyWith() 无参数等价原始对象', () {
      // **Validates: Requirements 3.6, 12.13**

      Glados<YuNiEngineConfig>(any.engineConfig).test(
        'c.copyWith() == c for all valid configs',
        (c) {
          expect(
            c.copyWith(),
            equals(c),
            reason: 'copyWith() with no arguments should return an equal object',
          );
        },
      );
    });

    group('Property 10: copyWith(speed: s) 只改变 speed 字段', () {
      // **Validates: Requirements 3.6, 12.14**

      Glados2<YuNiEngineConfig, double>(
        any.engineConfig,
        any.validSpeed,
      ).test(
        'copyWith(speed: s) only changes speed, other fields remain unchanged',
        (c, s) {
          final updated = c.copyWith(speed: s);

          expect(updated.speed, equals(s),
              reason: 'speed should be updated to $s');
          expect(updated.loop, equals(c.loop),
              reason: 'loop should remain unchanged');
          expect(updated.mute, equals(c.mute),
              reason: 'mute should remain unchanged');
          expect(updated.autoPlay, equals(c.autoPlay),
              reason: 'autoPlay should remain unchanged');
          expect(updated.hardwareAcceleration, equals(c.hardwareAcceleration),
              reason: 'hardwareAcceleration should remain unchanged');
          expect(updated.headers, equals(c.headers),
              reason: 'headers should remain unchanged');
        },
      );
    });

    group('Property 11: speed 越界构造抛出 AssertionError', () {
      // **Validates: Requirements 3.7, 12.13**

      Glados<double>(any.invalidSpeed).test(
        'constructing YuNiEngineConfig with out-of-range speed throws AssertionError',
        (speed) {
          expect(
            () => YuNiEngineConfig(speed: speed),
            throwsA(isA<AssertionError>()),
            reason: 'speed $speed is out of range [0.25, 4.0]',
          );
        },
      );
    });
  });
}
