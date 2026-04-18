import 'dart:io';

import 'package:glados/glados.dart';
import 'package:yu_ni_player/src/core/yu_ni_video_source.dart';

void main() {
  group('YuNiVideoSource', () {
    group('constructor assertions', () {
      test('throws AssertionError when both url and file are null', () {
        expect(
          () => YuNiVideoSource(
            id: 'test-id',
            url: null,
            file: null,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws AssertionError when id is empty string', () {
        expect(
          () => YuNiVideoSource(
            id: '',
            url: 'https://example.com/video.mp4',
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts valid url source', () {
        expect(
          () => const YuNiVideoSource(
            id: 'test-id',
            url: 'https://example.com/video.mp4',
          ),
          returnsNormally,
        );
      });

      test('accepts valid file source', () {
        expect(
          () => YuNiVideoSource(
            id: 'test-id',
            file: File('/path/to/video.mp4'),
          ),
          returnsNormally,
        );
      });
    });

    group('isLandscape property', () {
      test('returns true when aspectRatio is null', () {
        const source = YuNiVideoSource(
          id: 'test-id',
          url: 'https://example.com/video.mp4',
          aspectRatio: null,
        );
        expect(source.isLandscape, isTrue);
      });

      test('returns true when aspectRatio is exactly 1.0', () {
        const source = YuNiVideoSource(
          id: 'test-id',
          url: 'https://example.com/video.mp4',
          aspectRatio: 1.0,
        );
        expect(source.isLandscape, isFalse);
      });

      test('returns false when aspectRatio is less than 1.0', () {
        const source = YuNiVideoSource(
          id: 'test-id',
          url: 'https://example.com/video.mp4',
          aspectRatio: 0.5,
        );
        expect(source.isLandscape, isFalse);
      });

      test('returns true when aspectRatio is greater than 1.0', () {
        const source = YuNiVideoSource(
          id: 'test-id',
          url: 'https://example.com/video.mp4',
          aspectRatio: 1.78,
        );
        expect(source.isLandscape, isTrue);
      });
    });

    group('Property 8: isLandscape 横屏判断', () {
      // **Validates: Requirements 4.5, 12.11, 12.12**

      Glados<double>(any.double).test(
        'aspectRatio > 1.0 implies isLandscape == true',
        (aspectRatio) {
          // Only test values greater than 1.0
          if (aspectRatio <= 1.0) return;

          final source = YuNiVideoSource(
            id: 'test-id',
            url: 'https://example.com/video.mp4',
            aspectRatio: aspectRatio,
          );

          expect(source.isLandscape, isTrue,
              reason: 'aspectRatio $aspectRatio > 1.0 should be landscape');
        },
      );

      Glados<double>(any.double).test(
        'aspectRatio <= 1.0 implies isLandscape == false',
        (aspectRatio) {
          // Only test values <= 1.0
          if (aspectRatio > 1.0) return;

          final source = YuNiVideoSource(
            id: 'test-id',
            url: 'https://example.com/video.mp4',
            aspectRatio: aspectRatio,
          );

          expect(source.isLandscape, isFalse,
              reason: 'aspectRatio $aspectRatio <= 1.0 should not be landscape');
        },
      );
    });
  });
}
