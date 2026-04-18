/// yu_ni_player — 统一视频播放器 base 库
///
/// 提供核心抽象、对象池、UI 组件，不包含任何播放器 SDK 依赖。
/// 按需引入对应的引擎包：
/// - `yu_ni_player_video_player_kit`：基于 video_player（全平台）
/// - `yu_ni_player_tx_player`：基于腾讯 super_player（iOS/Android）
/// - `yu_ni_player_media_kit`：基于 media_kit（全平台，开源）
library;

// ── 核心类型 ──────────────────────────────────────────────────────────────
export 'src/core/yu_ni_player_engine.dart';
export 'src/core/yu_ni_player_exception.dart';
export 'src/core/yu_ni_engine_config.dart';
export 'src/core/yu_ni_video_data.dart';
export 'src/core/yu_ni_video_source.dart';

// ── 注册与工厂层 ──────────────────────────────────────────────────────────
export 'src/registry/platform_key.dart';
export 'src/registry/yu_ni_player_factory.dart';
export 'src/registry/yu_ni_player_registry.dart';

// ── 对象池 ────────────────────────────────────────────────────────────────
export 'src/pool/yu_ni_player_pool.dart';

// ── 插件入口 ──────────────────────────────────────────────────────────────
export 'src/plugin/yu_ni_player_config.dart';
export 'src/plugin/yu_ni_player_plugin.dart';

// ── UI 组件 ───────────────────────────────────────────────────────────────
export 'src/ui/yu_ni_player_widget.dart';
export 'src/ui/yu_ni_player_controls.dart';
