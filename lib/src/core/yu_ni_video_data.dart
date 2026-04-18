/// 播放器运行时数据（可变，由引擎内部更新）
class YuNiVideoData {
  /// 视频总时长，初始值为 [Duration.zero]
  Duration duration = Duration.zero;

  /// 视频宽度（像素），初始值为 0
  double width = 0;

  /// 视频高度（像素），初始值为 0
  double height = 0;

  /// 视频宽高比，null 表示未知
  double? aspectRatio;

  /// 视频渲染是否已开始
  bool videoRenderStart = false;

  /// 当前播放位置（毫秒），null 表示未知
  int? posMilli;

  /// 缓冲进度百分比（0–100）
  int bufferPercent = 0;

  /// 最近一次错误（用于 errorBuilder 展示）
  Object? lastError;

  /// 将所有字段恢复为初始值
  void reset() {
    duration = Duration.zero;
    width = 0;
    height = 0;
    aspectRatio = null;
    videoRenderStart = false;
    posMilli = null;
    bufferPercent = 0;
    lastError = null;
  }
}
