import 'dart:async';
import 'dart:collection';

import '../core/yu_ni_player_engine.dart';
import '../core/yu_ni_video_source.dart';
import '../registry/yu_ni_player_factory.dart';

/// 播放器实例缓存池（单例）
///
/// 使用 LRU（最近最少使用）策略管理活跃播放器实例，
/// 并维护一个回收池以复用已释放的实例，减少创建开销。
///
/// - 活跃池（[_active]）：当前正在使用的播放器，上限为 [_maxActiveCount]
/// - 回收池（[_recycled]）：已释放但可复用的播放器，上限为 [_maxRecycledCount]
/// - [currentPlayer]：当前正在播放的播放器，受 LRU 保护，不会被淘汰
class YuNiPlayerPool {
  YuNiPlayerPool._();

  /// 单例实例
  static final YuNiPlayerPool instance = YuNiPlayerPool._();

  // ── 内部数据结构 ──────────────────────────────────────────────

  /// 活跃播放器映射（LinkedHashMap 保证插入顺序，用于 LRU）
  final LinkedHashMap<String, YuNiPlayerEngine> _active = LinkedHashMap();

  /// 回收池（LIFO 复用：removeLast 取最新回收的实例）
  final List<YuNiPlayerEngine> _recycled = [];

  /// 活跃池最大容量（默认 3）
  int _maxActiveCount = 3;

  /// 回收池最大容量（默认 2）
  int _maxRecycledCount = 2;

  /// 当前正在播放的播放器（受 LRU 保护，不参与淘汰）
  YuNiPlayerEngine? currentPlayer;

  // ── 只读 getter（测试用）──────────────────────────────────────

  /// 当前活跃播放器数量
  int get activeCount => _active.length;

  /// 当前回收池中的播放器数量
  int get recycledCount => _recycled.length;

  // ── 配置 ──────────────────────────────────────────────────────

  /// 更新活跃池和回收池的容量上限。
  void configure({
    required int maxActiveCount,
    required int maxRecycledCount,
  }) {
    _maxActiveCount = maxActiveCount;
    _maxRecycledCount = maxRecycledCount;
  }

  // ── 核心 API ──────────────────────────────────────────────────

  /// 获取与 [source] 对应的播放器实例。
  ///
  /// 查找顺序：
  /// 1. 命中活跃缓存（[source.id] 已在 [_active] 中）→ 刷新 LRU 位置后返回
  /// 2. 未命中 → 尝试从回收池复用
  /// 3. 回收池为空 → 通过 [YuNiPlayerFactory.create] 新建
  ///
  /// 获取后会触发 LRU 淘汰检查，确保活跃池不超过 [_maxActiveCount]。
  YuNiPlayerEngine acquire(YuNiVideoSource source) {
    // 1. 查找活跃缓存
    final existing = _active[source.id];
    if (existing != null) {
      if (!existing.isDisposed) {
        // 命中且未销毁：更新 source 引用，刷新 LRU 位置（移到末尾）
        existing.videoSource = source;
        _active.remove(source.id);
        _active[source.id] = existing;
        return existing;
      } else {
        // 命中但已销毁：移除，继续走后续逻辑
        _active.remove(source.id);
      }
    }

    // 2. 未命中：尝试复用回收池
    final YuNiPlayerEngine player;
    if (_recycled.isNotEmpty) {
      // 取最新回收的实例（LIFO）
      player = _recycled.removeLast();
      player.videoSource = source;
    } else {
      // 回收池为空：新建实例
      player = YuNiPlayerFactory.create(source);
    }

    // 3. 放入活跃缓存
    _active[source.id] = player;

    // 4. LRU 淘汰检查
    _evictLRU();

    return player;
  }

  /// 释放 [source] 对应的播放器，将其移入回收池（或直接销毁）。
  ///
  /// 若 [currentPlayer] 指向该播放器，则同时清除 [currentPlayer] 引用。
  Future<void> release(YuNiVideoSource source) async {
    final player = _active[source.id];
    if (player == null) return;

    if (currentPlayer == player) {
      currentPlayer = null;
    }

    _active.remove(source.id);
    await _recycleOrDispose(player);
  }

  /// 销毁所有活跃和回收中的播放器实例，清空两个集合。
  Future<void> disposeAll() async {
    // 销毁所有活跃实例
    for (final player in _active.values) {
      await player.dispose();
    }

    // 销毁所有回收实例
    for (final player in _recycled) {
      await player.dispose();
    }

    currentPlayer = null;
    _active.clear();
    _recycled.clear();
  }

  // ── 私有方法 ──────────────────────────────────────────────────

  /// LRU 淘汰：当活跃池超过上限时，淘汰最旧的非 [currentPlayer] 条目。
  ///
  /// [_active] 是 [LinkedHashMap]，按插入顺序迭代，第一个即为最旧。
  /// 若所有活跃实例都是 [currentPlayer]，则停止淘汰。
  void _evictLRU() {
    while (_active.length > _maxActiveCount) {
      String? evictKey;
      for (final key in _active.keys) {
        if (_active[key] != currentPlayer) {
          evictKey = key;
          break; // 找到最旧的非 currentPlayer 条目
        }
      }
      if (evictKey == null) break; // 所有活跃都是 currentPlayer，停止

      final evicted = _active.remove(evictKey)!;
      unawaited(_recycleOrDispose(evicted));
    }
  }

  /// 将播放器移入回收池，若回收池已满则淘汰最旧的回收实例。
  ///
  /// 调用 [YuNiPlayerEngine.release] 释放 native 资源（保留实例可复用）。
  /// 若回收池已满，先 [YuNiPlayerEngine.dispose] 最旧的回收实例再加入新实例。
  ///
  /// 注意：回收池列表的增删操作在 `await` 之前同步完成，以避免并发调用时
  /// 多个 `unawaited(_recycleOrDispose(...))` 同时读取到相同的列表长度，
  /// 导致回收池超出上限。
  Future<void> _recycleOrDispose(YuNiPlayerEngine player) async {
    // 同步决定：将 player 加入回收池，或淘汰最旧的回收实例
    YuNiPlayerEngine? toDispose;
    if (_recycled.length < _maxRecycledCount) {
      // 回收池未满：直接加入（占位，后续 release 完成后可复用）
      _recycled.add(player);
    } else {
      // 回收池已满：同步移除最旧的（index 0），加入新实例
      toDispose = _recycled.removeAt(0);
      _recycled.add(player);
    }

    // 异步释放 native 资源（保留实例可重新 init）
    await player.release();

    // 异步销毁被淘汰的旧实例
    if (toDispose != null) {
      await toDispose.dispose();
    }
  }
}
