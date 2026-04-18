/// 播放器状态枚举
///
/// 描述 [YuNiPlayerEngine] 在任意时刻所处的状态。
/// 状态转换由引擎内部通过 [YuNiPlayerEngine.updateState] 驱动。
enum YuNiPlayerState {
  /// 初始状态，引擎尚未初始化
  idle,

  /// 正在加载 / 初始化中
  loading,

  /// 正在播放
  playing,

  /// 已暂停（就绪，可恢复播放）
  paused,

  /// 播放完成（已到达视频末尾）
  completed,

  /// 播放出错
  error,

  /// 缓冲中（播放中断，等待数据）
  buffering,
}
