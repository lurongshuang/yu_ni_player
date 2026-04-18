/// yu_ni_player_base — 抽象基础库单一入口
///
/// 导出所有公开 API，消费方只需一行 import：
/// ```dart
/// import 'package:yu_ni_player_base/yu_ni_player_base.dart';
/// ```
library yu_ni_player_base;

// Core
export 'src/core/yu_ni_player_engine.dart';
export 'src/core/yu_ni_player_state.dart';
export 'src/core/yu_ni_video_source.dart';
export 'src/core/yu_ni_video_data.dart';
export 'src/core/yu_ni_engine_config.dart';
export 'src/core/yu_ni_player_exception.dart';

// Registry
export 'src/registry/platform_key.dart';
export 'src/registry/yu_ni_player_registry.dart';
export 'src/registry/yu_ni_player_factory.dart';

// Pool
export 'src/pool/yu_ni_player_pool.dart';

// Plugin
export 'src/plugin/yu_ni_player_plugin.dart';
export 'src/plugin/yu_ni_player_config.dart';

// UI
export 'src/ui/yu_ni_player_widget.dart';
export 'src/ui/yu_ni_player_controls.dart';
