/// 插件统一异常类
///
/// 用于在插件内部统一抛出结构化错误信息，包含人类可读的描述和可选的原始异常。
class YuNiPlayerException implements Exception {
  const YuNiPlayerException(this.message, {this.cause});

  /// 人类可读的错误描述
  final String message;

  /// 原始异常（可选）
  final Object? cause;

  @override
  String toString() {
    if (cause != null) {
      return 'YuNiPlayerException: $message\nCaused by: $cause';
    }
    return 'YuNiPlayerException: $message';
  }
}
