/// yu_ni_player — 统一视频播放器插件
library;

// ── 核心类型 ──────────────────────────────────────────────────────────────
// YuNiPlayerState 通过 yu_ni_player_engine.dart 的 export 传递
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
